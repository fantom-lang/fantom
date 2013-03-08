
class ComboTest : Test
{
    Void testNullSelected()
    {
        combo := Combo() { items = ["aaa", "bbb"]}
        verifyEq(0, combo.selectedIndex)
        verifyEq("aaa", combo.selected)

        combo.selected = null

        verifyEq(0, combo.selectedIndex)
        verifyEq("aaa", combo.selected)

    }
}
