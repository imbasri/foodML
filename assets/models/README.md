# TensorFlow Lite Food Classification Model

This directory contains the TensorFlow Lite model for food classification.

## Model Information:
- Model: food_classification_model.tflite
- Labels: food_labels.txt
- Input size: 224x224 RGB image
- Output: Probability scores for each food category

## Usage:
The TensorFlowLiteService will automatically load and use this model for local food recognition.

Note: In a production environment, you would place a pre-trained food classification model here.
For development/testing purposes, the service includes fallback logic.

PLACEHOLDER_MODEL_FILE=food_classifier.tflite