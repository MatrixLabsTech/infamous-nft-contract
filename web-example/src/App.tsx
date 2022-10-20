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
    const client = new InfamousNFTClientImpl(AptosNetwork.Devnet)
    const tokenData = await client.tokenOwned(
      '0x523b8b8eae6ada0e4af325518c014dbbf8a6ad6404cc4c5583a3b6115e491974'
    )

    console.log({ tokenData })
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
