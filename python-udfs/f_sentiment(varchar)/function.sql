/*
Purpose: This function will return the sentiment of a text field using the nltk library.

2023-09-29: written by rjvgupta
*/
--
CREATE OR REPLACE FUNCTION f_sentiment (text VARCHAR)
RETURNS VARCHAR IMMUTABLE AS $$
  from nltk.sentiment import SentimentIntensityAnalyzer
  sia = SentimentIntensityAnalyzer()
  return sia.polarity_scores(text)
$$ LANGUAGE plpythonu;
