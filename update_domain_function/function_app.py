import logging
import azure.functions as func
import os
import requests

app = func.FunctionApp()

# Trigger function to update the SSL expiry date every day at midnight
@app.timer_trigger(schedule="0 0 * * *", arg_name="myTimer", run_on_startup=True,
              use_monitor=True) 


# Define the function to update the SSL expiry date
def update_domain_ssl_expiry_date(myTimer: func.TimerRequest) -> None:
    if myTimer.past_due:
        logging.info('The timer is past due!')

    # Get the SSL Monitor URL from the environment variables
    ssl_monitor_url = os.getenv("SSL_MONITOR_URL")

    if not ssl_monitor_url:
        logging.info('SSL Monitor URL not found')
        return
    
    try:
        logging.info(f"SSL Monitor URL: {ssl_monitor_url}")
        response = requests.get(ssl_monitor_url)
        logging.info(f"Response Status Code: {response.status_code}")
    except Exception as e:
        logging.error(f"Error: {e}")

    logging.info('Python timer trigger function executed.')