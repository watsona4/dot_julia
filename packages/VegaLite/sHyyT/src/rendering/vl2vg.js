'use strict';

const vl = require('../../deps/node_modules/vega-lite');

function read() {
    return new Promise((resolve, reject) => {
        let text = '';

        process.stdin.setEncoding('utf8');
        process.stdin.on('error', err => { reject(err); });
        process.stdin.on('data', chunk => { text += chunk; });
        process.stdin.on('end', () => { resolve(text); });
    });
};

function compile(vlSpec) {
    try {
        const result = vl.compile(vlSpec);

        // TODO: deal with errors
        const vgSpec = result.spec;

        process.stdout.write(JSON.stringify(vgSpec) + '\n');
    }
    catch (err) {
        console.error(err)
        process.exit(1)
    }
}

read()
    .then(text => compile(JSON.parse(text)))
    .catch(err => console.error(err));
