from magenta.models.improv_rnn import improv_rnn_generate as gen
from flask import Flask, jsonify, render_template, request
import sys
import json

#FLASK_APP=test.py flask run

app = Flask(__name__)

gen.FLAGS.config = 'chord_pitches_improv'
gen.FLAGS.bundle_file = 'chord_pitches_improv.mag'
gen.output_dir = '~/test/tmp/generated'
gen.FLAGS.num_outputs = 1
gen.FLAGS.primer_melody = "[60]"
gen.FLAGS.backing_chords = 'Dmaj7'

@app.route('/generate', methods=['POST'])
def generate():   
    print(request.form.get('primer_melody'))
    print(request.form.get('backing_chords'))

    gen.FLAGS.primer_melody = request.form.get('primer_melody')
    gen.FLAGS.backing_chords = request.form.get('backing_chords')

    jsonstr = gen.main("")
    print(jsonstr)
    return jsonstr

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, threaded=True)    