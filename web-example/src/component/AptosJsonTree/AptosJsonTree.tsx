import cn from 'classnames'

import { JSONTree } from 'react-json-tree'
import styles from './AptosJsonTree.module.less'

interface AptosJsonTreeProps {
  className?: string
  data: any
}

export function AptosJsonTree(props: AptosJsonTreeProps) {
  const { className, data } = props

  return (
    <div className={cn(styles.AptosJsonTree, className)}>
      <JSONTree data={data} hideRoot={true} />
    </div>
  )
}
