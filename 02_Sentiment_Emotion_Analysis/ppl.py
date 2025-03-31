from pygments import highlight
from pyplutchik import plutchik
import matplotlib.pyplot as plt

# venv311\Scripts\activate #paste this is ternimal, followed by below.
# python ppl.py

# --- Data Definitions (keep these as they are) ---
# --- Fluoride Values ---
primary_emotions_fluoride = {
    'joy': [0.00, 0.03, 0.00], # serenity, joy, ecstasy
    'trust': [0.02, 0.05, 0.02], # acceptance, trust, admiration
    'fear': [0.19, 0.05, 0.00], # apprehension, fear, terror
    'surprise': [0.02, 0.01, 0.00], # distraction, surprise, amazement
    'sadness': [0.01, 0.01, 0.00], # pensiveness, sadness, grief
    'disgust': [0.00, 0.54, 0.00], # boredom, disgust, loathing
    'anger': [0.24, 0.14, 0.00], # annoyance, anger, rage
    'anticipation': [0.15, 0.03, 0.00], # interest, anticipation, vigilance
}

primary_dyads_fluoride = {
    'aggressiveness': 0.00,
    'alarm': 0.04,
    'contempt': 0.28,
    'disappointment': 0.04,
    'love': 0.00,
    'optimism': 0.04,
    'remorse': 0.00,
    'submission': 0.00,
}

secondary_dyads_fluoride = {
    'guilt': 0.00,
    'curiosity': 0.23,
    'despair': 0.00,
    'unbelief': 0.05,
    'envy': 0.00,
    'cynism': 0.23,
    'pride': 0.01,
    'hope': 0.00,
}

tertiary_dyads_fluoride = {
    'delight': 0.04,
    'sentimentality': 0.01,
    'shame': 0.00,
    'outrage': 0.06,
    'pessimism': 0.01,
    'morbidness': 0.03,
    'dominance': 0.00,
    'anxiety': 0.01,
}

opposite_dyads_fluoride = {
    'bittersweetness': 0.00,
    'ambivalence': 0.00,
    'frozenness': 0.00,
    'confusion': 0.02
}

# --- General Values ---
primary_emotions_general = {
    'joy': [0.01, 0.08, 0.01], # serenity, joy, ecstasy
    'trust': [0.03, 0.03, 0.07], # acceptance, trust, admiration
    'fear': [0.09, 0.02, 0.00], # apprehension, fear, terror
    'surprise': [0.03, 0.01, 0.01], # distraction, surprise, amazement
    'sadness': [0.01, 0.03, 0.00], # pensiveness, sadness, grief
    'disgust': [0.00, 0.39, 0.00], # boredom, disgust, loathing
    'anger': [0.18, 0.16, 0.00], # annoyance, anger, rage
    'anticipation': [0.10, 0.04, 0.00], # interest, anticipation, vigilance
}

primary_dyads_general = {
    'aggressiveness': 0.01,
    'alarm': 0.00,
    'contempt': 0.28,
    'disappointment': 0.06,
    'love': 0.02,
    'optimism': 0.04,
    'remorse': 0.00,
    'submission': 0.00,
}

secondary_dyads_general = {
    'guilt': 0.00,
    'curiosity': 0.15,
    'despair': 0.00,
    'unbelief': 0.03,
    'envy': 0.00,
    'cynism': 0.15,
    'pride': 0.02,
    'hope': 0.00,
}

tertiary_dyads_general = {
    'delight': 0.06,
    'sentimentality': 0.01,
    'shame': 0.00,
    'outrage': 0.04,
    'pessimism': 0.01,
    'morbidness': 0.01,
    'dominance': 0.01,
    'anxiety': 0.01,
}

opposite_dyads_general = {
    'bittersweetness': 0.00,
    'ambivalence': 0.01,
    'frozenness': 0.00,
    'confusion': 0.04
}

# --- Create the combined plot ---

# 1. Create a figure and a grid of subplots
# We need 5 plots. A 2x3 grid works well, leaving one subplot empty.
# Adjust figsize as needed for your screen resolution and desired output size.
fig, axs = plt.subplots(2, 5, figsize=(30, 12)) # 2 rows, 5 columns

# 2. Flatten the axs array for easier indexing (optional but convenient)
axs_flat = axs.flatten()

# 3. Call plutchik for each dataset, passing the corresponding axis object
plutchik(primary_emotions_general, ax=axs_flat[0], title='Primary Emotions for General Posts', title_size=12, normalize=0.39, highlight_emotions = ['admiration'])

plutchik(primary_dyads_general, ax=axs_flat[1], title='Primary Dyads for General Posts', title_size=12, normalize=0.28)

plutchik(secondary_dyads_general, ax=axs_flat[2], title='Secondary Dyads for General Posts', title_size=12, normalize=0.15)

plutchik(tertiary_dyads_general, ax=axs_flat[3], title='Tertiary Dyads for General Posts', title_size=12, normalize=0.06)

plutchik(opposite_dyads_general, ax=axs_flat[4], title='Opposite Dyads for General Posts', title_size=12, normalize=0.04)

plutchik(primary_emotions_fluoride, ax=axs_flat[5], title='Primary Emotions for Fluoride Posts', title_size=12, normalize=0.54)

plutchik(primary_dyads_fluoride, ax=axs_flat[6], title='Primary Dyads for Fluoride Posts', title_size=12, normalize=0.28)

plutchik(secondary_dyads_fluoride, ax=axs_flat[7], title='Secondary Dyads for Fluoride Posts', title_size=12, normalize=0.36)

plutchik(tertiary_dyads_fluoride, ax=axs_flat[8], title='Tertiary Dyads for Fluoride Posts', title_size=12, normalize=0.06)

plutchik(opposite_dyads_fluoride, ax=axs_flat[9], title='Opposite Dyads for Fluoride Posts', title_size=12, normalize=0.02)


# 5. Adjust layout to prevent titles/labels overlapping
plt.tight_layout()

# 6. Show the entire figure *once*
# plt.show()

# 7. (Optional) Save the figure to a file
#fig.savefig("all_plutchik_plots.png", dpi=1000) # Example: Save as PNG
fig.savefig("all_plutchik_plots.pdf")       # Example: Save as PDF