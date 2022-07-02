import pandas as pd
import matplotlib.pyplot as plt
import os, json
import pandas as pd
from PIL import Image
import numpy as np
from numpy import asarray
from sklearn.preprocessing import LabelEncoder
from tensorflow.keras.utils import to_categorical
from sklearn.model_selection import train_test_split


path = '../matjari/data/matjari-dataset-cleaned.csv'
path_to_json = "../raw_data/pictures-from-script/ALL Pictures"


def get_data():
    df = pd.read_csv(path, sep='\t')
    df.columns = ['Product Label','url']
    return df

def load_json(df):
    json_files = [pos_json for pos_json in os.listdir(path_to_json) if pos_json.endswith('.json')]
    jsons_data = pd.DataFrame(columns=["url", "key", "status", "error_message", "width", "height", "original_width", "original_height", "exif", "md5"])

    for index, js in enumerate(json_files):
        with open(os.path.join(path_to_json, js)) as json_file:
            json_text = json.load(json_file)

            # here you need to know the layout of your json and each json has to have
            # the same structure
            url = json_text["url"]
            key = json_text["key"]
            status = json_text["status"]
            error_message = json_text["error_message"]
            width = json_text["width"]
            height = json_text["height"]
            original_width = json_text["original_width"]
            original_height = json_text["original_height"]
            exif = json_text["exif"]
            md5 = json_text["md5"]
            # here I push a list of data into a pandas DataFrame at row given by 'index'
            jsons_data.loc[index] = [url, key, status, error_message, width, height, original_width, original_height, exif, md5]
            df2 = pd.DataFrame(jsons_data)
    df_merge = df.merge(df2, how='inner', on='url')
    return df_merge

def load_img(df_merge):
    A = []
    for i in range(0, len(df_merge)):
        img = Image.open('../raw_data/pictures-from-script/ALL Pictures/' + str(df_merge['key'][i]) + '.jpg')
        img_array = asarray(img)
        A.append(img_array)
    df_merge['A'] = A
    return df_merge

def load_nrows(df_merge):
    nrows = 100
    df_merge = df_merge.sample(n=nrows, random_state = 11)
    return df_merge

def encod(df_merge):
    encoder = LabelEncoder()
    df_merge['Label_encoded'] = encoder.fit_transform(df_merge['Product Label'])
    y_encod = df_merge['Label_encoded']
    y = to_categorical(y_encod, num_classes=y_encod.nunique())
    X = np.array(df_merge['A'].tolist())
    return X, y

def split_data(X, y):
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3)
    return X_train, X_test, y_train, y_test

if __name__ == '__main__':
    pass
    #the shape of X must be 3D
    #assert shape of X_train, X_test, y_train, y_test
