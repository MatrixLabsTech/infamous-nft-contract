import { Types } from 'aptos'
import cn from 'classnames'
import React, { useCallback } from 'react'
import { useEffect, useState } from 'react'
import { Button, ListGroup, Spinner } from 'react-bootstrap'
import { getClient, infamousManagerCap, moduleAddress } from '../const'

import styles from './Read.module.less'
import { ResourceAccountRead } from './ResourceAccountRead'
import { TokenStoreHandle } from './ResourceAccountRead/TokenStoreHandle'

interface ReadProps {
  className?: string
  address: string
}
function noop() {}

const resourceMinterInfo = `${moduleAddress}::${infamousManagerCap}::ManagerAccountCapability`

export function Read(props: ReadProps) {
  const { className } = props

  const [resources, setResources] = React.useState<Types.MoveResource[]>([])

  const [loading, setLoading] = useState(false)
  const fetchResource = useCallback(async () => {
    setLoading(true)
    let network = await (window as any).aptos.network()
    getClient(network)
      .getAccountResources(moduleAddress)
      .then((resources: Types.MoveResource[]) => {
        setLoading(false)
        setResources(
          resources.filter(
            (r) =>
              r.type === resourceMinterInfo ||
              r.type === '0x3::token::TokenStore'
          )
        )
      })
  }, [])

  console.log(resources)

  useEffect(() => {
    fetchResource()
  }, [fetchResource])

  const [modalShow, setModalShow] = useState(false)
  const [resourceAddress, setResourceAddress] = useState('')
  const handleQueryResource = useCallback((address: string) => {
    setResourceAddress(address)
    setModalShow(true)
  }, [])

  return (
    <div className={cn(styles.Read, className)}>
      <div style={{ textAlign: 'right', padding: '15px 0' }}>
        <Button
          variant="primary"
          disabled={loading}
          onClick={!loading ? fetchResource : noop}
        >
          {loading ? 'Reloading…' : 'Click to reload'}
        </Button>
      </div>

      {loading && <Spinner animation="border" size="sm" />}
      {!loading && resources.length === 0 && <div>no data</div>}
      <ListGroup as="ol" numbered>
        {resources.map((resource) => {
          console.log(resource) //ccc-log
          return (
            <ListGroup.Item
              key={resource.type}
              as="li"
              className="d-flex justify-content-between align-items-start"
            >
              <div className="ms-2 me-auto">
                <div className="fw-bold">{resource.type}</div>
                <br />
                <pre>{JSON.stringify(resource.data, null, 2)}</pre>
                {resource.type === '0x3::token::TokenStore' && (
                  <TokenStoreHandle
                    address={resourceAddress}
                    tokensHandle={
                      (resource.data as any).tokens.handle as string
                    }
                  />
                )}
                {resource.type === resourceMinterInfo && (
                  <Button
                    variant="primary"
                    onClick={() =>
                      handleQueryResource(
                        (resource.data as any).signer_cap.account
                      )
                    }
                  >
                    Get NFT Resource
                  </Button>
                )}
              </div>
            </ListGroup.Item>
          )
        })}
      </ListGroup>

      <ResourceAccountRead
        resourceAddress={resourceAddress}
        show={modalShow}
        onHide={() => setModalShow(false)}
      />
    </div>
  )
}
