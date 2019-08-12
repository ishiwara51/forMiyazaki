# セッション変数の取得
from setting_db import session
# Userモデルの取得
from user_db import *

# DBにレコードの追加
user = User()
user.name = 'root'
session.add(user)  
session.commit()

# Userテーブルのnameカラムをすべて取得
users = session.query(User).all()
for user in users:
    print(user.name)
