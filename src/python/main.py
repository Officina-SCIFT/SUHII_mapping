from src.python.utils import get_time_window
from src.python.processing import Processing
from src.python.settings import PATH
import argparse


parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--city', type=str, default='Bologna')
args = parser.parse_args()
city = args.city
start, end = get_time_window()

processing = Processing(city, start, end)
processing.process(PATH)
