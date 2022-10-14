import { Types } from 'aptos'
import cn from 'classnames'
import React, { useState } from 'react'
import { useEffect } from 'react'
import { Accordion, Modal, ModalProps, Spinner } from 'react-bootstrap'
import { client } from '../../const'
import { CollectionDataHandle } from './CollectionDataHandle'

import styles from './ResourceAccountRead.module.less'
import { TokenStoreHandle } from './TokenStoreHandle'

interface ResourceAccountReadProps extends ModalProps {
  className?: string
  resourceAddress: string
}

const collectionResource = `0x3::token::Collections`
const tokenStoreResource = `0x3::token::TokenStore`
export function ResourceAccountRead(props: ResourceAccountReadProps) {
  const { className, resourceAddress, show } = props

  const [loading, setLoading] = useState(false)
  const [resources, setResources] = React.useState<Types.MoveResource[]>([])
  useEffect(() => {
    if (resourceAddress) {
      setLoading(true)
      client.getAccountResources(resourceAddress).then((resources) => {
        setLoading(false)
        setResources(
          resources.filter(
            (r) =>
              r.type === collectionResource || r.type === tokenStoreResource
          )
        )
      })
    }
  }, [resourceAddress, show])

  return (
    <div className={cn(styles.ResourceAccountRead, className)}>
      <Modal
        {...props}
        size="lg"
        aria-labelledby="contained-modal-title-vcenter"
        centered
      >
        <Modal.Header closeButton>
          <Modal.Title id="contained-modal-title-vcenter">
            {ellipsis(resourceAddress)}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body className={styles.content}>
          {loading && <Spinner animation="border" size="sm" />}
          {!loading && resources.length === 0 && <div>no data</div>}
          <Accordion>
            {resources.map((resource) => {
              return (
                <Accordion.Item eventKey={resource.type} key={resource.type}>
                  <Accordion.Header>{resource.type}</Accordion.Header>
                  <Accordion.Body>
                    {/* <AptosJsonTree data={resource.data} /> */}
                    {resource.type === '0x3::token::Collections' && (
                      <CollectionDataHandle
                        address={resourceAddress}
                        collectionDataHandle={
                          (resource.data as any).collection_data
                            .handle as string
                        }
                        tokenDataHandle={
                          (resource.data as any).token_data.handle as string
                        }
                      />
                    )}
                    {resource.type === '0x3::token::TokenStore' && (
                      <TokenStoreHandle
                        address={resourceAddress}
                        tokensHandle={
                          (resource.data as any).tokens.handle as string
                        }
                      />
                    )}
                  </Accordion.Body>
                </Accordion.Item>
              )
            })}
          </Accordion>
        </Modal.Body>
      </Modal>
    </div>
  )
}

function ellipsis(address: string) {
  return `${address.substr(0, 6)}...${address.substr(-6)}`
}
