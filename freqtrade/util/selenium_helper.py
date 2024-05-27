import os
import json
import random
import string
import time
from datetime import datetime
from selenium.webdriver import ActionChains, Keys
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

def capture_tradingview_screenshot(symbol: str):
    image_path = None

    # TODO: from pair create url, mapping file json lay tu user_data/pair_url_map.json

    # get symbol from msg
    # msg pair có dạng symbol/base_currency:base_currency
    # example: BTC/USDT:USDT
    # sẽ tách symbol = BTC
    tradingview_symbol_format = symbol + 'USDT'
    if '1000' in tradingview_symbol_format:
        tradingview_symbol_format += '.P'

    # Lấy tradingview shared chart token
    custom_config_path = os.path.join(os.getcwd(), "user_data", "custom_config.json")
    share_chart_token = None
    try:
        with open(custom_config_path, "r") as f:
            config = json.load(f)
            share_chart_token = config['tradingview']['share_chart_token']
    except:
        print("Get tradingview shared chart token error.")

    print(f"Tradingview shared chart token: {share_chart_token}")

    # create url
    if share_chart_token:
        url = f"https://www.tradingview.com/chart/{share_chart_token}/?symbol={tradingview_symbol_format}"
    else:
        url = f"https://www.tradingview.com/chart/?symbol={tradingview_symbol_format}"

    try:
        chrome_options = Options()
        chrome_options.add_argument("--headless=")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--hide-scrollbars")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--force-dark-mode")

        driver = webdriver.Chrome(options=chrome_options)

        # Navigate to the URL
        driver.get(url)

        # Wait for a few seconds for the new page to load
        time.sleep(3)

        # set tradingview fullscreen
        ActionChains(driver).key_down(Keys.SHIFT).send_keys("f").key_up(Keys.SHIFT).perform()
        time.sleep(2)

        # Create directory name based on current date
        current_date = datetime.now().strftime("%Y%m%d")
        directory_name = os.path.join(os.getcwd(), "user_data", "tradingview", current_date)

        # Create the directory if it doesn't exist
        if not os.path.exists(directory_name):
            os.makedirs(directory_name)

        # Generate a random string for file name
        random_string = ''.join(random.choices(string.ascii_lowercase + string.digits, k=10))

        # Construct the file path
        image_path = os.path.join(directory_name, f"{random_string}.png")

        driver.save_screenshot(image_path)

        driver.quit()
    except:
        print("Tradingview snapshot error")

    return image_path
