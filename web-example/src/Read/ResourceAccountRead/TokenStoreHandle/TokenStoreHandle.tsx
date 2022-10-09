import cn from 'classnames'
import { useCallback, useState } from 'react'
import { Button, Form, Spinner } from 'react-bootstrap'
import { AptosJsonTree } from '../../../component/AptosJsonTree'
import { tableItem } from '../../utils'

import styles from './TokenStoreHandle.module.less'

interface TokenStoreHandleProps {
  className?: string
  tokensHandle: string
  address: string
}

export function TokenStoreHandle(props: TokenStoreHandleProps) {
  const { className, tokensHandle, address } = props

  const [querying, setQuerying] = useState(false)
  const [token, setToken] = useState<any>()
  const handleGetToken = useCallback(
    async (e: any) => {
      e.preventDefault()

      try {
        setQuerying(true)

        const formData = new FormData(e.target)
        const formProps = Object.fromEntries(formData)

        const token = await getToken(
          tokensHandle,
          formProps.creator as string,
          formProps.collection as string,
          formProps.name as string,
          formProps.property_version as string
        )
        setQuerying(false)
        setToken(token)
      } catch (e) {
        setQuerying(false)
      }
    },
    [tokensHandle]
  )

  return (
    <div className={cn(styles.TokenStoreHandle, className)}>
      <Form onSubmit={handleGetToken}>
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
        <Form.Group className="mb-3">
          <Form.Control
            type="text"
            placeholder="property_version"
            name="property_version"
          />
        </Form.Group>
        <Button variant="primary" type="submit" disabled={querying}>
          {querying && (
            <>
              <Spinner animation="border" size="sm" />
              &nbsp;&nbsp;
            </>
          )}
          GetToken
        </Button>
      </Form>

      {!!token && <AptosJsonTree data={token} />}
      <br />
    </div>
  )
}

async function getToken(
  handle: string,
  creator: string,
  collection_name: string,
  token_name: string,
  property_version: string
): Promise<any> {
  const token_data_id = {
    creator: creator,
    collection: collection_name,
    name: token_name,
  }

  const token_id = {
    token_data_id,
    property_version,
  }

  const token = await tableItem(
    handle,
    '0x3::token::TokenId',
    '0x3::token::Token',
    token_id
  )

  return token
}
