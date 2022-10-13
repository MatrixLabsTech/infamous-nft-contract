import React, { useMemo } from 'react'
import { Alert, Button, Tab, Tabs } from 'react-bootstrap'
import { moduleAddress } from './const'
import { Read } from './Read'
import { Writer } from './Writer'

import { InfamousNFTClientImpl } from '@white-matrix/infamous-contract-sdk'
import { AptosNetwork } from '@white-matrix/infamous-contract-sdk/dist/InfamousNFTClientImpl'

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
    const client = new InfamousNFTClientImpl(AptosNetwork.Devnet)
    const collectInfo = await client.collectionInfo()
    console.log({ collectInfo }) //ccc-log

    const history = await client.wearWeaponHistory()
    console.log(history)

    // const tokenStaked = await client.tokenStaked(
    //   '0x0629ff667db2f4f337abfa47ec88f2e5a1c98beb14c1e870a14785666a6d80c6'
    // )
    // console.log(tokenStaked) //ccc-log

    // const tokenData = await client.tokenData(tokenStaked[0])
    // console.log(tokenData)

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
