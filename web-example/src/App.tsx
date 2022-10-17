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

  // const _getCollection = async () => {
  //   const client = new InfamousNFTClientImpl(AptosNetwork.Devnet)
  //   const collectInfo = await client.collectionInfo()
  //   console.log({ collectInfo }) //ccc-log

  //   const tokenIds = await client.tokenIdsOwned(
  //     '0xa793c7456c449a09f94e829c5f0dc8a4ded9334775fd8ca7d54b82d096ccee06'
  //   )

  //   const level = await client.tokenLevel(tokenIds[0])
  //   console.log({ level })

  //   const isReveled = await client.tokenIsReveled(tokenIds[0])
  //   console.log({ isReveled })

  //   const history = await client.wearWeaponHistory()
  //   console.log(history)
  // }

  return (
    <div className="App">
      {/* sdk test
      <button onClick={_getCollection}>getCollection</button> */}
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
