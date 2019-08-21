from magenta.models.improv_rnn import improv_rnn_generate as gen
from flask import Flask, request
import MySQLdb
import sys
import datetime

#https://qiita.com/sireline/items/8980110d945313cf7fab#step4---mysqlを利用する

app = Flask(__name__)

gen.FLAGS.config = 'chord_pitches_improv'
gen.FLAGS.bundle_file = 'chord_pitches_improv.mag'
gen.output_dir = '~/test/tmp/generated'
gen.FLAGS.num_outputs = 1
gen.FLAGS.primer_melody = "[60]"
gen.FLAGS.backing_chords = 'Dmaj7'

def ExecuteQuery(sql):
    conn = MySQLdb.connect(
 user='root',
 passwd='password',
 host='utjam-db.cpmduxvg8wt5.us-east-1.rds.amazonaws.com',
 db='utjam',
 port=3306)
    cur = conn.cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    return_str = ''
    for i in rows:
        print(i)
        return_str + str(i)
    cur.close
    conn.close
    return ""


@app.route('/generate', methods=['POST'])
def generate():   
    print(request.form.get('primer_melody'))
    print(request.form.get('backing_chords'))

    if request.form.get('primer_melody') and request.form.get('backing_chords'):
        gen.FLAGS.primer_melody = request.form.get('primer_melody')
        gen.FLAGS.backing_chords = request.form.get('backing_chords')

    str_to_return = gen.main("")

    gen.FLAGS.primer_melody = "[60]"
    gen.FLAGS.backing_chords = 'Dmaj7'

    return str_to_return

@app.route('/first_login', methods=['POST'])
def first_login():
    if request.form.get('user_id') and request.form.get('uuid'):
        stmt = str('insert into user_info (user_id, uuid, created_at, lesson_completed, updated_at, transfer_id) values ('
                    + str(request.form.get('user_id'))
                    + '\', cast(\''
                    + str(request.form.get('uuid'))
                    + '\' as binary(16), cast(\''
                    + str(datetime.date.today())
                    + '\' as date), 0, cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime), %s)')
        return_str = ExecuteQuery(stmt)
        return return_str
    else:
        return 'Your device was not able to be certificated.'

@app.route('/chorus_end', methods=['POST'])
def chorus_end():
    if request.form.get('user_id') and request.form.get('sequence') and request.form.get('composition_name') and request.form.get('chorus'):
        stmt = str('insert into play_record (user_id, composition_name, played_at, sequence) value ('
                    + str(request.form.get('user_id'))
                    + '\', \''
                    + str(request.form.get('composition_name'))
                    + ', \''
                    + str(request.form.get('chorus'))
                    + '\', cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime), \''
                    + str(request.form.get('sequence'))
                    + '\')')
        return_str = ExecuteQuery(stmt)
        return return_str
    else:
        return 'Some value is missing in your request.'

@app.route('/tutorial_end', methods=['POST'])
def tutorial_end():
    if request.form.get('user_id') and request.form.get('lesson_num'):
        stmt = str('update user_info set updated_at=cast(\'%s\' as datetime), lesson_completed=%s where user_id=%s',
                    (str(datetime.datetime.now()), str(request.form.get('lesson_num')), request.form.get('user_id')))
        """
        stmt = str('update user_info set updated_at=cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime), lesson_completed='
                    + str(request.form.get('lesson_num')) 
                    + ' where user_id='
                    + request.form.get('user_id'))
        """
        return_str = ExecuteQuery(stmt)
        return return_str
    else:
        return 'Some value is missing in your request.'
        
@app.route('/transfer_id_created', methods=['POST'])
def transfer_id_created():
    if request.form.get('user_id') and request.form.get('lesson_num'):
        stmt = str('update user_info set updated_at=cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime), lesson_completed='
                    + str(request.form.get('lesson_num')) 
                    + ' where user_id='
                    + request.form.get('user_id'))
        return_str = ExecuteQuery(stmt)
        return return_str
    else:
        return 'Some value is missing in your request.'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)    