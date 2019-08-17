from magenta.models.improv_rnn import improv_rnn_generate as gen
from flask import Flask, request
from flaskext.mysql import MySQL
import sys
import datetime

app = Flask(__name__)

mysql = MySQL()

app.config['MYSQL_DATABASE_USER'] = 'root'
app.config['MYSQL_DATABASE_PASSWORD'] = 'password'
app.config['MYSQL_DATABASE_DB'] = 'utjam'
app.config['MYSQL_DATABASE_HOST'] = 'utjam-db.cpmduxvg8wt5.us-east-1.rds.amazonaws.com'
app.config['MYSQL_DATABASE_PORT'] = 3306

mysql.init_app(app)

gen.FLAGS.config = 'chord_pitches_improv'
gen.FLAGS.bundle_file = 'chord_pitches_improv.mag'
gen.output_dir = '~/test/tmp/generated'
gen.FLAGS.num_outputs = 1
gen.FLAGS.primer_melody = "[60]"
gen.FLAGS.backing_chords = 'Dmaj7'

def ExecuteQuery(sql):
  cur = mysql.connect().cursor()
  cur.execute(sql)
  """
  results = [dict((cur.description[i][0], value)
    for i, value in enumerate(row)) for row in cur.fetchall()]
  return results
  """


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
    if request.form.get('user_id'):
        ExecuteQuery('insert into user_info (user_id, created_at, lesson_completed, updated_at) values ('
                    + str(request.form.get('user_id'))
                    + ', cast(\''
                    + str(datetime.date.today())
                    + '\' as date), 0, cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime))')
        return 'Query succeded.'
    else:
        return 'Your device was not able to be certificated.'

@app.route('/chorus_end', methods=['POST'])
def chorus_end():
    if request.form.get('user_id') and request.form.get('play_record') and request.form.get('composition_name'):
        ExecuteQuery('insert into play_record (user_id, composition_name, played_at, sequence) value ('
                    + str(request.form.get('user_id'))
                    + ', \''
                    + str(request.form.get('composition_name'))
                    + '\', cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime), '
                    + str(request.form.get('sequence'))
                    + ')')
        return 'Query succeded.'
    else:
        return 'Some value is missing in your request.'

@app.route('/tutorial_end', methods=['POST'])
def tutorial_end(id):
    if request.form.get('user_id') and request.form.get('play_record') and request.form.get('composition_name'):
        ExecuteQuery('insert into play_record (user_id, composition_name, played_at, sequence) value ('
                    + str(request.form.get('user_id'))
                    + ', \''
                    + str(request.form.get('composition_name'))
                    + '\', cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime), '
                    + str(request.form.get('sequence'))
                    + ')')
        ExecuteQuery('update user_info set updated_at=cast(\''
                    + str(datetime.datetime.now())
                    + '\' as datetime) where user_id='
                    + request.form.get('user_id')
                    + ')')
        return 'Query succeded.'
    else:
        return 'Some value is missing in your request.'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)    