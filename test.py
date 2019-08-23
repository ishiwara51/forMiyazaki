from magenta.models.improv_rnn import improv_rnn_generate as gen
from flask import Flask, request
import MySQLdb
import sys
import datetime
import random

#https://it-engineer-lab.com/archives/1181#_INSERT

app = Flask(__name__)

gen.FLAGS.config = 'chord_pitches_improv'
gen.FLAGS.bundle_file = 'chord_pitches_improv.mag'
gen.output_dir = '~/test/tmp/generated'
gen.FLAGS.num_outputs = 1
gen.FLAGS.primer_melody = "[60]"
gen.FLAGS.backing_chords = 'Dmaj7'

def ExecuteQuery(stmt, param_placeholders):
    conn = MySQLdb.connect(
 user='root',
 passwd='password',
 host='utjam-db.cpmduxvg8wt5.us-east-1.rds.amazonaws.com',
 db='utjam',
 port=3306)
    cur = conn.cursor()
    cur.execute(stmt, param_placeholders)
    result = cur.fetchall()
    print(result)
    conn.commit()
    cur.close
    conn.close

    return_str=""
    with io.StringIO() as f:
        # 標準出力を f に切り替える。
        sys.stdout = f
        return_str = f.getvalue()
        sys.stdout = sys.__stdout__
    return return_str


@app.route('/generate', methods=['POST'])
def generate():   
    print(request.form.get('primer_melody'))
    print(request.form.get('backing_chords'))

    if request.form.get('primer_melody') and request.form.get('backing_chords'):
        gen.FLAGS.primer_melody = request.form.get('primer_melody')
        gen.FLAGS.backing_chords = request.form.get('backing_chords')

    return_str = gen.main("")

    gen.FLAGS.primer_melody = "[60]"
    gen.FLAGS.backing_chords = 'Dmaj7'

    return return_str

@app.route('/first_login', methods=['POST'])
def first_login():
    if request.form.get('uuid') and request.form.get('lesson_completed'):
        stmt = 'insert into user_info (uuid, created_at, lesson_completed, updated_at) values (%s, cast(%s as datetime), %s, cast(%s as datetime))'
        param_placeholders = (str(request.form.get('uuid')), str(datetime.datetime.now()), str(request.form.get('lesson_completed')), str(datetime.datetime.now()))
        print(stmt % param_placeholders)
        return_str = ExecuteQuery(stmt, param_placeholders)
        return return_str
    else:
        return 'Your device was not able to be certificated.'

@app.route('/transfer', methods=['POST'])
def transfer():
    if request.form.get('uuid') and request.form.get('transfer_id'):
        stmt = 'update user_info set uuid=%s, updated_at=%s, transfer_id=%s where transfer_id=%s'
        param_placeholders = (str(request.form.get('uuid')), str(datetime.datetime.now()), None, str(request.form.get('transfer_id')))
        print(stmt % param_placeholders)
        return_str = ExecuteQuery(stmt, param_placeholders)
        return return_str
    else:
        return 'Your device was not able to be certificated.'

@app.route('/chorus_end', methods=['POST'])
def chorus_end():
    if request.form.get('uuid') and request.form.get('sequence') and request.form.get('composition_name') and request.form.get('chorus'):
        stmt = 'insert into play_record (uuid, composition_name, chorus, played_at, sequence) value (%s, %s, %s, cast(%s as datetime), %s)'
        param_placeholders = (str(request.form.get('uuid')), str(request.form.get('composition_name')), str(request.form.get('chorus')), str(datetime.datetime.now()), str(request.form.get('sequence')))
        print(stmt % param_placeholders)
        return_str = ExecuteQuery(stmt, param_placeholders)
        return return_str
    else:
        return 'Some value is missing in your request.'

@app.route('/tutorial_end', methods=['POST'])
def tutorial_end():
    if request.form.get('uuid') and request.form.get('lesson_completed'):
        stmt = 'update user_info set updated_at=cast(%s as datetime), lesson_completed=%s where uuid=%s'
        param_placeholders = (str(datetime.datetime.now()), int(request.form.get('lesson_completed')), str(request.form.get('uuid')))
        print(stmt % param_placeholders)
        return_str = ExecuteQuery(stmt, param_placeholders)
        return return_str
    else:
        return 'Some value is missing in your request.'
        
@app.route('/transfer_id_created', methods=['POST'])
def transfer_id_created():
    if request.form.get('uuid'):
        stmt = 'update user_info set transfer_id=%s where uuid=%s'
        transfer_id = random.randint(-2147483648, 2147483647)
        param_placeholders = (transfer_id, str(request.form.get('uuid')))
        print(stmt % param_placeholders)
        return_str = ExecuteQuery(stmt, param_placeholders)
        return str(transfer_id)
    else:
        return 'Some value is missing in your request.'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)    