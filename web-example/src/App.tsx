import React, { useMemo } from 'react'
import { Alert, Button, Tab, Tabs } from 'react-bootstrap'
import { moduleAddress } from './const'
import { Read } from './Read'
import { Writer } from './Writer'

import { InfamousNFTClientImpl } from '@white-matrix/infamous-contract-sdk'

function App() {
  const [address, setAddress] = React.useState<string>('')
  React.useEffect(() => {
    const getaccount = async () => {
      try {
        await window.aptos.connect()
        window.aptos
          .account()
          .then((data: { address: string }) => setAddress(data.address))
      } catch (e) {}
    }

    getaccount()
  }, [])

  const isModuleOwner = useMemo(() => {
    return address === moduleAddress
  }, [address])

  const _getCollection = async () => {
    const client = new InfamousNFTClientImpl('devnet')
    const collectInfo = await client.collectionInfo()
    console.log({ collectInfo }) //ccc-log

    const coll = await client.tokenClient.getCollectionData(
      '0x307bd9d1be75ccd2f7670c5b7564b0cd26b41c1841b455ea6a0ea9eda0e0266f',
      "Alice's"
    )
    console.log({ coll })

    const tokenOwned = await client.tokenOwned(
      '0xc0db5b48fd82d6aaa00bac2570e22e6faccd0e8561b8d0813307b76cb354096f'
    )
    console.log(tokenOwned) //ccc-log

    // const property = await client.tokenProperty('Infamous #1')
    // console.log(property) //ccc-log

    // const minted = await client.tokenMinted(
    //   '0x90c1d4adb9668bb84aa16666abaf2870f6a7a0f05778e600ace09865994de948'
    // )
    // console.log(minted) //ccc-log
  }

  return (
    <div className="App">
      sdk test
      <button onClick={_getCollection}>getCollection</button>
      {address ? (
        isModuleOwner ? (
          <Alert variant="info">
            Hi Module Owner (<code>{address}</code>)!
          </Alert>
        ) : (
          <Alert variant="info">
            Hi (<code>{address}</code>)!
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
