import stripe
from flask import Flask
from flask import request
from flask import json

app = Flask(__name__)

@app.route('/pay', methods=['POST'])
def pay():
    # Set this to your Stripe secret key (use your test key!)
    stripe.api_key = "<you-stripe-secret-key"

    # Parse the request as JSON
    json = request.get_json(force=True)

    # Get the credit card details
    token = json['stripeToken']
    amount = json['amount']
    description = json['description']
    print json['shipping']["zip"]
    # Create the charge on Stripe's servers - this will charge the user's card
    try:
      charge = stripe.Charge.create(
          amount=amount, # amount in cents, again
          currency="usd",
          card=token,
          description=description
      )
    except stripe.CardError, e:
      # The card has been declined
      pass

    return "Success"

if __name__ == '__main__':
    # Set as 0.0.0.0 to be accessible outside your local machine
    app.run(debug=True, host= '0.0.0.0')
