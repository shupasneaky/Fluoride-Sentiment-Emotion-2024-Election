from pyplutchik import plutchik

emotions_simple = {
	'joy': 1,
	'trust': 0.6,
	'fear': 0.7,
	'surprise': 1,
	'sadness': 1,
	'disgust': 0.95,
	'anger': 0.64,
	'anticipation': 1
	}

plutchik(emotions_simple) # scores = emotions_simple