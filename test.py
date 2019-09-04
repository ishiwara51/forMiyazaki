from magenta.models.improv_rnn import improv_rnn_generate as gen
from flask import Flask, request
import sys

#https://it-engineer-lab.com/archives/1181#_INSERT

app = Flask(__name__)

gen.FLAGS.config = 'chord_pitches_improv'
gen.FLAGS.bundle_file = 'chord_pitches_improv.mag'
gen.output_dir = '~/test/tmp/generated'
gen.FLAGS.num_outputs = 1
gen.FLAGS.primer_melody = "[60]"
gen.FLAGS.backing_chords = 'Dmaj7'
gen.FLAGS.qpm = 120

@app.route('/generate', methods=['POST'])
def generate():   
    print(request.form.get('primer_melody'))
    print(request.form.get('backing_chords'))
    print(request.form.get('qpm'))

    if request.form.get('primer_melody') and request.form.get('backing_chords'):
        gen.FLAGS.primer_melody = request.form.get('primer_melody')
        gen.FLAGS.backing_chords = request.form.get('backing_chords')
    if request.form.get('qpm'):
        gen.FLAGS.qpm = int(request.form.get('qpm'))

    return_str = gen.main("")

    gen.FLAGS.primer_melody = "[60]"
    gen.FLAGS.backing_chords = 'Dmaj7'
    gen.FLAGS.qpm = 120

    return return_str

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)    