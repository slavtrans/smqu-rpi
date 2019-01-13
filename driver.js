require('dotenv').config()

const SerialPort = require('serialport')
const Readline = require('@serialport/parser-readline')
const StringDecoder = require('string_decoder').StringDecoder
const request = require('request')

const serialPort = process.env.SCAN_PORT
const scanUrl    = process.env.SCAN_URL

console.log('Started')

const port = new SerialPort(serialPort, function (error) {
  if (err) {
    return console.log('Error: ', error.message)
  }
})

const parser = port.pipe(new Readline({ delimiter: '\r\n' }))
parser.on('data', console.log)

port.on('readable', function () {
  const data = port.read()
  const decoder = new StringDecoder('utf8')
  const text = decoder.write(data)

  console.log('Read', text)

  request.post(
    {
      url: scanUrl,
      formData: {
        text: text
      }
    },
    function optionalCallback(error, httpResponse, body) {
      if (error) {
        return console.error('Request failed:', error)
      }
    }
  )
})

function wait() {
  setTimeout(wait, 1000)
}

wait()

console.log('Exit')
