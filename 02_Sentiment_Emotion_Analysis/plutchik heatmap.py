from pyplutchik import plutchik

emo = {
    'joy': [.01, .01, .03],
    'trust': [.00, .06, .10],
    'fear': [.02, .1, .04],
    'surprise': [0.00, .01, .03],
    'sadness': [0.00, .01, .01],
    'disgust': [.07, .11, .03],
    'anger': [.05, .12, .04],
    'anticipation': [.01, .07, .09]
}

plutchik(emo)


primary_dyads = {
    'love': 0,
    'submission': 0,
    'alarm': 0,
    'disappointment': .59,
    'remorse': .01,
    'contempt': .34,
    'aggressiveness': .04,
    'optimism': .03
}

plutchik(primary_dyads)
