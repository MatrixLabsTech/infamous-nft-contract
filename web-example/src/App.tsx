import React, { useMemo } from 'react'
import { Alert, Button, Tab, Tabs } from 'react-bootstrap'
import { moduleAddress } from './const'
import { Read } from './Read'
import { Writer } from './Writer'

import { InfamousNFTClientImpl } from '@white-matrix/infamous-contract-sdk'
import { AptosNetwork } from '@white-matrix/infamous-contract-sdk/dist/InfamousNFTClientImpl'

function App() {
  const [address, setAddress] = React.useState<string>('')
  const [network, setNetwork] = React.useState<string>('')
  React.useEffect(() => {
    const getaccount = async () => {
      try {
        await window.aptos.connect()
        window.aptos
          .account()
          .then((data: { address: string }) => setAddress(data.address))
        let network = await window.aptos.network()
        setNetwork(network)
      } catch (e) {}
    }

    getaccount()
  }, [])

  const isModuleOwner = useMemo(() => {
    return address === moduleAddress
  }, [address])

  const _getCollection = async () => {
    const client = new InfamousNFTClientImpl(AptosNetwork.Testnet)
    // const tokenId = await client.resolveTokenId('Infamous #1')

    // const airdroped = await client.tokenAirdroped(5, tokenId)

    // console.log(airdroped)

    const owned = await await client.queryMyEquipments(
      '0x2839acfa2c4e3942c9733c0ebb236c0a9b9d79971efac97d32e394787d9ec740'
    )

    console.log(owned)

    // console.log(JSON.stringify(tokenId))

    // const mintTime = await client.tokenMintTime(tokenId)

    // console.log(mintTime)

    // const tokenId = await client.resolveTokenId('Infamous #1')
    // const events = await client.wearWeaponTotal(tokenId)

    // if (events) {
    //   console.log(events)
    //   const paged = await client.wearWeaponPage(events, {
    //     start: 0,
    //     limit: 3,
    //   })
    //   console.log(paged)
    // }

    // console.log(tokenId)

    // const isOwner = await client.isTokenOwner(
    //   '0x2839acfa2c4e3942c9733c0ebb236c0a9b9d79971efac97d32e394787d9ec740',
    //   tokenId
    // )

    // console.log({ isOwner })
  }

  return (
    <div className="App">
      sdk test
      <button onClick={_getCollection}>getCollection</button>
      {address ? (
        isModuleOwner ? (
          <Alert variant="info">
            Hi Module Owner (<code>{address}</code>)[<code>{network}</code>]!
          </Alert>
        ) : (
          <Alert variant="info">
            Hi (<code>{address}</code>)[<code>{network}</code>]!
          </Alert>
        )
      ) : (
        <div style={{ textAlign: 'right', padding: '15px' }}>
          <Button variant="primary">Connect</Button>
        </div>
      )}
      <br />
      <Tabs
        defaultActiveKey="read"
        id="uncontrolled-tab-example"
        className="mb-3"
      >
        <Tab eventKey="read" title="Read Resource">
          <Read address={address} />
        </Tab>
        <Tab eventKey="write" title="Write Resource">
          <Writer />
        </Tab>
      </Tabs>
    </div>
  )
}

export default App
