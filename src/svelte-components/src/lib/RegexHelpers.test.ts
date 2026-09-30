import { describe, expect, it } from 'vitest'
import { numberWithUnit } from './RegexHelpers'

describe('numberWithUnit', () => {
  it('parses metric values and converts imperial values to millimeters', () => {
    const metric = numberWithUnit.parse('25.4 mm')
    const imperial = numberWithUnit.parse('1 in')

    expect(metric).toMatchObject({ value: 25.4, metric: true })
    expect(metric?.toMetric()).toBe(25.4)
    expect(imperial).toMatchObject({ value: 1, metric: false })
    expect(imperial?.toMetric()).toBe(25.4)
  })

  it('normalizes recognized fractions and rejects invalid values', () => {
    expect(numberWithUnit.normalize('0.5 inches')).toBe('1/2 in')
    expect(numberWithUnit.normalize('not a measurement')).toBe('')
  })
})
