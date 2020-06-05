'use strict'

const TelCLient = (socket, STARTTLS, onLine, onStarttls) => {
  STARTTLS = STARTTLS.toUpperCase()
  let starttls = []
  socket.on('data', (data) => {
    let cmds = data.split('\r\n') // TODO: buffer split
    cmds.forEach((cmd, i) => {
      if (cmd.toUpperCase().startsWith(STARTTLS)) {
        let unparsed = cmds.slice(i + 1) // TODO: join \r\n ?
        socket.pause()
        onStarttls(socket, unparsed)
        // collect unparsed, concat to buffer
        // pause socket
        // call onStarttls
      } else {
        onLine(cmd)
      }
    })
  })
}

const net = require('net')
const tls = require('tls')
const stream = require('stream')
const sslConfig = require('ssl-config')('modern')

const DefPromise = () => {
  let _resolve
  let _reject
  new Promise((resolve, reject) => {
    _resolve = resolve
    _reject = reject
  }
  
  return {
    resolve: (...a) => _resolve(...a),
    reject: (...a) => _reject(...a)
  }
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
        secureContext: tls.createSecureContext({
          ciphers: sslConfig.ciphers,
          honorCipherOrder: true,
          secureOptions: sslConfig.minimumTLSVersion
        })
      }
      
      const mToSClient = new tls.TLSSocket(mToS, tlsServer)
      const mToCClient = new tls.TLSSocket(mToC, tlsClient)

      mToC.write(clientUnparsed)
      mToS.write(serverUnparsed)
      
      const secToC = DefPromise()
      const secToS = DefPromise()
      
      mToSClient.once('secureConnect', secToS.resolve)
      mToSClient.once('error', secToS.reject)
      mToCClient.once('secureConnect', secToC.resolve)
      mToCClient.once('error', secToC.reject)
      
      const client = await secToC
      const server = await secToS
      
      return [client, server]
    }
  }
}

server = net.createServer(async socket => {
  const tlsm = TLSMachine({})
  const tsockets = tlsm.connect()

  const client = new Promise((resolve, reject) => {
    const client = net.connect({ host: target, port: targetPort })
    client.once('error', reject)
    client.once('connected', () => {
      client.fromServer = TelClient(client, "220 2.0.0 Ready to start TLS", async (line) => {
        fromServer.writeLine(line)
      }, (socket, unparsed) => {
        tlsm.setServer(socket, unparsed)
      })
      resolve(client)
    })
  })
  
  const fromClient = TelClient(socket, "STARTTLS", async (line) => {
    await client
    client.fromServer.writeLine(line)
  }, (socket, unparsed) => {
    tlsm.setClient(socket, unparsed)
  })
  
  const [client, server] = await tsockets.connect()
  client.pipe(server)
  server.pipe(client)
})
