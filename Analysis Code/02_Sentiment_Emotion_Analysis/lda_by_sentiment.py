import os
import pandas as pd
import spacy
from gensim import corpora, models, utils
from gensim.models import CoherenceModel
from gensim.models.phrases import Phrases, Phraser
import pyLDAvis.gensim
import pyLDAvis
from wordcloud import WordCloud
import warnings
from gensim.parsing.preprocessing import STOPWORDS as GENSIM_STOPWORDS
from collections import Counter
import re

warnings.filterwarnings("ignore", category=DeprecationWarning)

nlp = spacy.load("en_core_web_sm", disable=["parser", "ner"])

custom_sw_path = r"path/to/google-10000-english.txt"
with open(custom_sw_path, encoding="utf-8") as f:
    google_words = [w.strip() for w in f if w.strip()]
custom_stop = set(google_words[:1000])
custom_stop.update({"fluoride","fluoridated","fluoridation","water"})
base_stopset = GENSIM_STOPWORDS.union(custom_stop)

def clean_text(text):
    return re.sub(r"[^a-zA-Z\s]", "", str(text))

def spacy_tokenize(text):
    text = clean_text(text)
    doc = nlp(text)
    return [token.lemma_.lower() for token in doc
            if token.pos_ in {"NOUN","ADJ","VERB"} and not token.is_stop]

def build_bigrams(docs):
    phrases = Phrases(docs, min_count=20, threshold=100)
    return Phraser(phrases)

def user_labels(df):
    m = {"Positive":1,"Neutral":0,"Negative":-1}
    df = df.copy()
    df["val"] = df["Sentiment"].map(m)
    return df.groupby("Author.ID")["val"].mean().apply(
        lambda x: "Positive" if x>0.5 else "Negative" if x< -0.5 else "Neutral"
    )

def prepare_docs(texts, stopset, bigram):
    docs = [spacy_tokenize(t) for t in texts if pd.notnull(t)]
    docs = [bigram[doc] for doc in docs]
    docs = [[w for w in doc if w not in stopset] for doc in docs]
    return docs

def eval_lda(dict_, corpus, docs, out, K, author_ids, texts):
    os.makedirs(out, exist_ok=True)
    print(f"Training LDA with {K} topics for output {out}...")

    lda = models.LdaModel(corpus=corpus, id2word=dict_,
                          num_topics=K, random_state=42,
                          passes=10, iterations=200,
                          alpha="auto", eta="auto")

    vis = pyLDAvis.gensim.prepare(lda, corpus, dict_)
    vis_file = os.path.join(out, f"ldavis_{K}_topics.html")
    pyLDAvis.save_html(vis, vis_file)

    labels = [max(lda.get_document_topics(b), key=lambda x: x[1])[0] for b in corpus]
    df_labels = pd.DataFrame({
        "Author.ID": author_ids,
        "Text_nolink": texts,
        "Assigned_Topic": labels
    })
    df_labels.to_csv(os.path.join(out, f"assignments_{K}_topics.csv"), index=False)

    for t in range(K):
        freqs = dict(lda.show_topic(t, topn=50))
        wc = WordCloud(width=800, height=400, background_color="white")
        wc.generate_from_frequencies(freqs)
        wc.to_file(os.path.join(out, f"wordcloud_topic{t}_K{K}.png"))

    coh = CoherenceModel(model=lda, texts=docs, dictionary=dict_, coherence="c_v").get_coherence()
    perp = lda.log_perplexity(corpus)
    words = sum([[w for w,_ in lda.show_topic(t,topn=10)] for t in range(K)],[])
    div = len(set(words))/len(words)
    return {"K":K,"Coherence":coh,"Perplexity":perp,"Diversity":div}

def main():
    data_dir = r"path/to/data/processed_data"
    res_dir = r"path/to/topic_models"
    df_f = pd.read_csv(os.path.join(data_dir,"fluoride.csv"))
    df_g = pd.read_csv(os.path.join(data_dir,"general.csv"))
    labels = user_labels(df_f)

    all_txt = pd.concat([df_f["Text_nolink"], df_g["Text_nolink"]]).dropna().tolist()
    all_tok = sum([utils.simple_preprocess(t) for t in all_txt],[])
    top10 = {w for w,_ in Counter(all_tok).most_common(10)}
    stopset = base_stopset.union(top10)

    for name,df in [("fluoride",df_f),("general",df_g)]:
        for sent in ["Positive","Neutral","Negative"]:
            grp = f"{name}_{sent.lower()}"
            print(f"\nProcessing group: {grp}")
            auth = labels[labels==sent].index
            subset = df[df["Author.ID"].isin(auth)]
            if subset.empty: continue
            txts = subset["Text_nolink"].tolist()
            init = [spacy_tokenize(t) for t in txts]
            bigram = build_bigrams(init)
            docs = prepare_docs(txts, stopset, bigram)
            dct = corpora.Dictionary(docs)
            dct.filter_extremes(no_below=2,no_above=0.2)
            corp = [dct.doc2bow(doc) for doc in docs]
            metrics=[]
            for K in range(4,11):
                out = os.path.join(res_dir,grp,f"{K}_topics")
                m = eval_lda(dct,corp,docs,out,K,subset["Author.ID"].tolist(),txts)
                metrics.append(m)
            pd.DataFrame(metrics).to_csv(os.path.join(res_dir,grp,"metrics.csv"),index=False)
            print(f"Saved metrics for {grp}")

if __name__=="__main__":
    main()