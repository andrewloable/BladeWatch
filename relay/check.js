'use strict'
// Checks a running relay from any machine that has its relay key:
//   node check.js [key-file]        (default: /etc/bladewatch-relay/key)
// Passes only if a member is let in AND a stranger is turned away.

const fs = require('fs')
const DHT = require('hyperdht')
const { deriveKeyPairs } = require('./relay')

const TIMEOUT_MS = 30_000

function attempt (relayPublicKey, keyPair) {
  const dht = new DHT()
  const started = Date.now()
  return new Promise((resolve) => {
    const socket = dht.connect(relayPublicKey, { keyPair })
    const timer = setTimeout(() => finish({ ok: false, why: 'timed out' }), TIMEOUT_MS)
    function finish (result) {
      clearTimeout(timer)
      socket.destroy()
      dht.destroy().then(() => resolve({ ...result, ms: Date.now() - started }))
    }
    socket.on('open', () => finish({ ok: true }))
    socket.on('error', (err) => finish({ ok: false, why: err.code || err.message }))
  })
}

async function main () {
  const keyFile = process.argv[2] || process.env.RELAY_KEY_FILE || '/etc/bladewatch-relay/key'
  const { server, member } = deriveKeyPairs(fs.readFileSync(keyFile, 'utf8'))

  const asMember = await attempt(server.publicKey, member)
  console.log(asMember.ok
    ? 'member:   let in after ' + asMember.ms + ' ms'
    : 'member:   NOT let in (' + asMember.why + ') -- is the relay running, and its UDP ports open?')

  const asStranger = await attempt(server.publicKey, DHT.keyPair())
  console.log(asStranger.ok
    ? 'stranger: LET IN -- the relay is not enforcing its key'
    : 'stranger: turned away (' + asStranger.why + ')')

  process.exitCode = asMember.ok && !asStranger.ok ? 0 : 1
}

main().catch((err) => {
  console.error('check failed: ' + err.message)
  process.exitCode = 1
})
