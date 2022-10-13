import { Types } from 'aptos'
import cn from 'classnames'
import React from 'react'
import { Accordion, Breadcrumb, Button, Form, Spinner } from 'react-bootstrap'
import {
  client,
  infamousBackendAuth,
  infamousBackendOpenBox,
  infamousBackendTokenWeaponAirdrop,
  infamousNft,
  infamousStake,
  infamousUpgradeLevel,
  infamousWeaponNft,
  infamousWeaponWear,
  metadataModuleName,
  moduleAddress,
} from '../const'

import styles from './Writer.module.less'

interface WriterProps {
  className?: string
}

interface IResourceMap {
  [key: string]: {
    result: boolean
    message: string
  }
}
interface ILoadingMap {
  [key: string]: boolean
}

function stringToHex(text: string) {
  const encoder = new TextEncoder()
  const encoded = encoder.encode(text)
  console.log(encoded) //ccc-log
  return Array.from(encoded, (i) => i.toString(16).padStart(2, '0')).join('')
}

function parseJson(text: string) {
  return JSON.parse(text)
}

function paramToHex(value: string, type: string) {
  if (type === 'address') {
    return value.startsWith('0x') ? value.substring(2) : value
  } else if (type === '0x1::string::String') {
    return value
  } else if (type === 'u64') {
    return value
  } else if (type === 'vector<u8>') {
    return stringToHex(value)
  } else if (type === 'vector<vector<u8>>') {
    const arr = parseJson(value)
    return arr.map((a: any) => stringToHex(a as string))
  } else if (
    type === 'vector<bool>' ||
    type === 'vector<0x1::string::String>'
  ) {
    return parseJson(value)
  }
  return value
}

export function Writer(props: WriterProps) {
  const { className } = props

  // Check for the module; show publish instructions if not present.
  const [modules, setModules] = React.useState<Types.MoveModuleBytecode[]>([])
  React.useEffect(() => {
    client.getAccountModules(moduleAddress).then((modules) => {
      console.log(modules) //ccc-log
      setModules(
        modules.filter((m) => {
          const moduleName = m.abi?.name || ''
          return (
            moduleName === metadataModuleName ||
            moduleName === infamousNft ||
            moduleName === infamousStake ||
            moduleName === infamousUpgradeLevel ||
            moduleName === infamousBackendOpenBox ||
            moduleName === infamousBackendAuth ||
            moduleName === infamousBackendTokenWeaponAirdrop ||
            moduleName === infamousWeaponWear
          )
        })
      )
    })
  }, [])

  const [isSaving, setIsSaving] = React.useState<ILoadingMap>({})
  const [handleInfo, setHandleInfo] = React.useState<IResourceMap>({})
  const handleSubmit = async (e: any, fun: string) => {
    e.preventDefault()

    const formData = new FormData(e.target)
    const formProps = Object.fromEntries(formData)

    const params: any[] = []
    Object.keys(formProps).forEach((key) => {
      const type = key.split('-')[2]
      if (type) {
        const value = (formProps[key] as string) || ''
        params.push(paramToHex(value, type))
      }
    })

    console.log(params) //ccc-log
    const transaction = {
      type: 'entry_function_payload',
      function: fun,
      arguments: params,
      type_arguments: [],
    }

    try {
      setIsSaving((prev) => ({ ...prev, [fun]: true }))
      await window.aptos.connect()

      const response = await window.aptos.signAndSubmitTransaction(transaction)

      if ((response as any).hash) {
        setHandleInfo((handleInfo) => ({
          ...handleInfo,
          [fun]: {
            result: true,
            message: `message hash: ${(response as any).hash}`,
          },
        }))
      } else {
        setHandleInfo((handleInfo) => ({
          ...handleInfo,
          [fun]: { result: false, message: response.message },
        }))
      }
    } catch (e) {
      console.log(e) //ccc-log

      setHandleInfo((handleInfo) => ({
        ...handleInfo,
        [fun]: {
          result: false,
          message: (e as unknown as any).message,
        },
      }))
    } finally {
      setIsSaving((prev) => ({ ...prev, [fun]: false }))
    }
  }

  return (
    <div className={cn(styles.Writer, className)}>
      {!!modules.length &&
        modules.map((module) => {
          if (module.abi) {
            const abi = module.abi
            return (
              <div
                className={styles.module}
                key={`${abi.address}::${abi.name}`}
              >
                <Breadcrumb>
                  <Breadcrumb.Item href="#">{abi.address}</Breadcrumb.Item>
                  <Breadcrumb.Item active>{abi.name}</Breadcrumb.Item>
                </Breadcrumb>
                <Accordion>
                  {abi.exposed_functions.map((fun) => (
                    <Accordion.Item eventKey={fun.name} key={fun.name}>
                      <Accordion.Header>{fun.name}</Accordion.Header>
                      <Accordion.Body>
                        <Form
                          onSubmit={(e) =>
                            handleSubmit(
                              e,
                              `${abi.address}::${abi.name}::${fun.name}`
                            )
                          }
                        >
                          {fun.params.map((p, index) => {
                            if (p !== '&signer') {
                              return (
                                <Form.Group
                                  className="mb-3"
                                  controlId="formBasicEmail"
                                  key={`${fun.name}::${index}`}
                                >
                                  <Form.Control
                                    type="text"
                                    placeholder={p}
                                    name={`params-${index}-${p}`}
                                  />
                                </Form.Group>
                              )
                            }
                            return null
                          })}
                          <Button
                            variant="primary"
                            type="submit"
                            disabled={
                              isSaving[
                                `${abi.address}::${abi.name}::${fun.name}`
                              ]
                            }
                          >
                            {isSaving[
                              `${abi.address}::${abi.name}::${fun.name}`
                            ] && (
                              <>
                                <Spinner animation="border" size="sm" />
                                &nbsp;&nbsp;
                              </>
                            )}
                            Submit
                          </Button>
                          {renderResult(
                            handleInfo,
                            `${abi.address}::${abi.name}::${fun.name}`
                          )}
                        </Form>
                      </Accordion.Body>
                    </Accordion.Item>
                  ))}
                </Accordion>
              </div>
            )
          }
          return null
        })}
    </div>
  )
}

function renderResult(resultMap: IResourceMap, fun: string) {
  const result = resultMap[fun]
  if (result) {
    return (
      <span
        className={cn(styles.msg, {
          [styles.error]: !result.result,
          [styles.info]: result.result,
        })}
      >
        {result.message}
      </span>
    )
  }
}
