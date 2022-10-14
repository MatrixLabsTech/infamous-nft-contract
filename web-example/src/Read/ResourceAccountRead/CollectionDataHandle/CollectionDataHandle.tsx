import cn from 'classnames'
import { useCallback, useState } from 'react'
import { Button, Form, Spinner } from 'react-bootstrap'
import { tableItem } from '../../utils'

import styles from './CollectionDataHandle.module.less'
import { AptosJsonTree } from '../../../component/AptosJsonTree'

interface CollectionDataHandleProps {
  className?: string
  collectionDataHandle: string
  tokenDataHandle: string
  address: string
}

export function CollectionDataHandle(props: CollectionDataHandleProps) {
  const { className, collectionDataHandle, tokenDataHandle, address } = props

  const [querying, setQuerying] = useState(false)
  const [tokenData, setTokenData] = useState<any>()
  const handleGetTokenData = useCallback(
    async (e: any) => {
      e.preventDefault()
      try {
        setQuerying(true)
        const formData = new FormData(e.target)
        const formProps = Object.fromEntries(formData)
        const tokenData = await getTokenData(
          tokenDataHandle,
          formProps.creator as string,
          formProps.collection as string,
          formProps.name as string
        )
        setQuerying(false)
        setTokenData(tokenData)
      } catch (e) {
        setQuerying(false)
      }
    },
    [tokenDataHandle]
  )

  const [queryCollectionDataing, setQueryCollectionDataing] = useState(false)
  const [collectionData, setCollectionData] = useState<any>()
  const handleGetCollectionData = useCallback(
    async (e: any) => {
      e.preventDefault()
      try {
        setQueryCollectionDataing(true)
        const formData = new FormData(e.target)
        const formProps = Object.fromEntries(formData)
        const collectionData = await getCollectionData(
          collectionDataHandle,
          formProps.collection as string
        )
        setQueryCollectionDataing(false)
        setCollectionData(collectionData) //ccc-log
      } catch (e) {
        setQueryCollectionDataing(false)
      }
    },
    [collectionDataHandle]
  )
  return (
    <div className={cn(styles.CollectionDataHandle, className)}>
      <Form onSubmit={handleGetTokenData}>
        <Form.Group className="mb-3">
          <Form.Control
            type="text"
            placeholder="creator"
            name="creator"
            defaultValue={address}
          />
        </Form.Group>
        <Form.Group className="mb-3">
          <Form.Control
            type="text"
            placeholder="collection"
            name="collection"
          />
        </Form.Group>
        <Form.Group className="mb-3">
          <Form.Control type="text" placeholder="name" name="name" />
        </Form.Group>
        <Button variant="primary" type="submit" disabled={querying}>
          {querying && (
            <>
              <Spinner animation="border" size="sm" />
              &nbsp;&nbsp;
            </>
          )}
          GetTokenData
        </Button>
      </Form>
      {!!tokenData && <AptosJsonTree data={tokenData} />}
      <br /> <hr />
      <Form onSubmit={handleGetCollectionData}>
        <Form.Group className="mb-3">
          <Form.Control
            type="text"
            placeholder="collection"
            name="collection"
          />
        </Form.Group>
        <Button
          variant="primary"
          type="submit"
          disabled={queryCollectionDataing}
        >
          {queryCollectionDataing && (
            <>
              <Spinner animation="border" size="sm" />
              &nbsp;&nbsp;
            </>
          )}
          GetCollectionData
        </Button>
      </Form>
      {!!collectionData && <AptosJsonTree data={collectionData} />}
      <br />
    </div>
  )
}

async function getCollectionData(
  handle: string,
  collection_name: string
): Promise<any> {
  let network = await (window as any).aptos.network()
  const collectionData = await tableItem(
    network,
    handle,
    '0x1::string::String',
    '0x3::token::CollectionData',
    collection_name
  )
  return collectionData
}

async function getTokenData(
  handle: string,
  creator: string,
  collection_name: string,
  token_name: string
): Promise<any> {
  const token_data_id = {
    creator: creator,
    collection: collection_name,
    name: token_name,
  }

  let network = await (window as any).aptos.network()
  const token = await tableItem(
    network,
    handle,
    '0x3::token::TokenDataId',
    '0x3::token::TokenData',
    token_data_id
  )
  return token
}
