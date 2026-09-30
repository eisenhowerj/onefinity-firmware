import { compile } from 'svelte/compiler'
import { describe, expect, it } from 'vitest'
import componentSource from './MessageDialog.svelte?raw'

describe('MessageDialog', () => {
  it('compiles with accessible labels for its title and content', () => {
    const { js, warnings } = compile(componentSource, {
      filename: 'MessageDialog.svelte',
      generate: 'server',
    })

    expect(warnings).toEqual([])
    expect(js.code).toContain('message-dialog-title')
    expect(js.code).toContain('message-dialog-content')
    expect(js.code).toContain('aria-labelledby')
    expect(js.code).toContain('aria-describedby')
  })
})
