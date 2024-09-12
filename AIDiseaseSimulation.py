import random
from datetime import datetime, timedelta

class OutbreakPredictor:
    def __init__(self):
        self.locations = ["New York", "London", "Tokyo", "São Paulo", "Mumbai"]
        self.diseases = ["COVID-19", "Influenza", "Dengue", "Malaria"]

    def generate_prediction(self):
        location = random.choice(self.locations)
        disease = random.choice(self.diseases)
        risk_level = random.uniform(0, 1)
        prediction_date = datetime.now() + timedelta(days=random.randint(1, 30))

        return {
            "location": location,
            "disease": disease,
            "risk_level": risk_level,
            "prediction_date": prediction_date.strftime("%Y-%m-%d")
        }

    def simulate_predictions(self, num_predictions=5):
        predictions = [self.generate_prediction() for _ in range(num_predictions)]
        return predictions

def main():
    predictor = OutbreakPredictor()
    predictions = predictor.simulate_predictions()

    print("Simulated Outbreak Predictions:")
    for i, prediction in enumerate(predictions, 1):
        print(f"\nPrediction {i}:")
        print(f"Location: {prediction['location']}")
        print(f"Disease: {prediction['disease']}")
        print(f"Risk Level: {prediction['risk_level']:.2f}")
        print(f"Prediction Date: {prediction['prediction_date']}")

    # Simulate an alert for the highest risk prediction
    highest_risk = max(predictions, key=lambda x: x['risk_level'])
    if highest_risk['risk_level'] > 0.7:  # Arbitrary threshold for demonstration
        print(f"\nALERT! High risk of {highest_risk['disease']} outbreak in {highest_risk['location']}!")
        print(f"Risk Level: {highest_risk['risk_level']:.2f}")
        print(f"Predicted for: {highest_risk['prediction_date']}")
        print("Immediate action required!")

if __name__ == "__main__":
    main()
