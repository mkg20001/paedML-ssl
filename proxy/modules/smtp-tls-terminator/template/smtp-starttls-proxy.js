'use strict'

function splitBuffer (data, thing) {
  thing = Buffer.from(thing)
  if (data.indexOf(thing) === -1) return [data]
  let offset = 0
  const out = []

  let match
  while ((match = data.indexOf(thing, offset)) !== -1) {
    out.push(data.slice(offset, match))
    offset = match + thing.length
  }

  if (offset < data.length) {
    out.push(data.slice(offset))
  }

  return out
}

let [target, targetPort, cert, key] = process.argv.slice(2)

targetPort = parseInt(targetPort, 10)

const TelClient = (socket, STARTTLS, onLine, onStarttls) => {
  STARTTLS = STARTTLS.toUpperCase()
  socket.on('data', (data) => {
    console.log(data, String(data))
    const cmds = splitBuffer(data, '\r\n') // TODO: buffer split
    cmds.forEach((cmd, i) => {
      console.log(i, String(cmd))
      if (!cmd.length) return
      if (String(cmd).toUpperCase().startsWith(STARTTLS)) {
        console.log('START')
        // collect unparsed, concat to buffer
        let unparsed = cmds.slice(i + 1) // TODO: join \r\n ?
        if (!unparsed.length) unparsed = Buffer.from('')
        else if (unparsed.length === 1) unparsed = cmds[0]
        else unparsed = unparsed.reduce((a, b) => Buffer.concat([a, Buffer.from('\r\n'), b]))
        // pause socket
        socket.pause()
        // transmit that line
        onLine(cmd)
        // call onStarttls
        onStarttls(socket, unparsed)
      } else {
        onLine(cmd)
      }
    })
  })

  return {
    writeLine: (b) => socket.write(Buffer.concat([b, Buffer.from("\r\n")]))
  }
}

const net = require('net')
const tls = require('tls')
const stream = require('stream')
const sslConfig = require('ssl-config')('modern')
const fs = require('fs')

const tlsParams = {
  cert: fs.readFileSync(cert),
  key: fs.readFileSync(key)
}

const DefPromise = () => {
  let _resolve
  let _reject

  const p = new Promise((resolve, reject) => {
    _resolve = resolve
    _reject = reject
  })

  p.resolve = (...a) => _resolve(...a)
  p.reject = (...a) => _reject(...a)

  return p
}

const TLSMachine = ({ cert, key }) => {
  const server = DefPromise()
  const client = DefPromise()

  return {
    setServer: (...a) => server.resolve(a),
    setClient: (...a) => client.resolve(a),
    connect: async () => {
      const [cToM, clientUnparsed] = await client
      const [sToM, serverUnparsed] = await server

      const mToS = new stream.Duplex()
      const mToC = new stream.Duplex()

      const tlsServer = {
        isServer: true,
        secureContext: tls.createSecureContext({
          cert,
          key,
          ciphers: sslConfig.ciphers,
          honorCipherOrder: true,
          secureOptions: sslConfig.minimumTLSVersion
        })
      }

      const tlsClient = {
        requestCert: true,
        secureContext: tls.createSecureContext({
          ciphers: sslConfig.ciphers,
          honorCipherOrder: true,
          secureOptions: sslConfig.minimumTLSVersion
        })
      }

      console.log("u", clientUnparsed, serverUnparsed)

      mToS.pause()
      mToC.pause()

      const mToSClient = new tls.TLSSocket(mToS, tlsServer)
      const mToCClient = new tls.TLSSocket(mToC, tlsClient)

      console.log(mToSClient)
      console.log(mToSClient.connect)

      mToSClient.connect(sToM)
      mToCClient.connect(cToM)

      /* mToC.write(clientUnparsed)
      mToS.write(serverUnparsed)

      cToM.pipe(mToC)
      mToC.pipe(cToM)

      sToM.pipe(mToS)
      mToS.pipe(sToM) */



      const secToC = DefPromise()
      const secToS = DefPromise()

      mToSClient.once('secureConnect', secToS.resolve)
      mToSClient.once('error', secToS.reject)
      mToCClient.once('secureConnect', secToC.resolve)
      mToCClient.once('error', secToC.reject)

      const _server = await secToS
      const _client = await secToC

      console.log("dcon")

      return [_client, _server]
    }
  }
}

const server = net.createServer(async socket => {
  socket.pause()

  const tlsm = TLSMachine(tlsParams)
  const tsockets = tlsm.connect()

  //TODO: handle end

  const fromClient = TelClient(socket, 'STARTTLS', async (line) => {
    fromServer = await fromServer
    fromServer.writeLine(line)
  }, (socket, unparsed) => {
    tlsm.setClient(socket, unparsed)
  })

  let fromServer = await new Promise((resolve, reject) => {
    const client = net.connect({ host: target, port: targetPort }, () => {
      const tClient = TelClient(client, '220 2.0.0 Ready to start TLS', async (line) => {
        fromClient.writeLine(line)
      }, (socket, unparsed) => {
        tlsm.setServer(socket, unparsed)
      })
      client.resume()
      resolve(tClient)
    })
    client.once('error', reject)
  })

  socket.resume()

  console.log('dada')

  const [client, server] = await tsockets
  client.pipe(server)
  server.pipe(client)
})

server.listen(targetPort + 1000)
