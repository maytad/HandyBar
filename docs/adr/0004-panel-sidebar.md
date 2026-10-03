# The menu bar panel uses a sidebar of features

The panel is about 520 pt wide: a sidebar lists the features with their status, and
the selected feature fills the rest. It reopens on the last feature used, and
Command-1 to Command-9 select features. Hiding and reordering features happens in a
separate Settings window, which also has a sidebar. The maintainer chose this so
that many future features stay one click away with every feature's status visible,
accepting a wider panel than Apple's guidance suggests for popovers.

## Considered options

- **Home list that opens one feature with a Back button, 320 pt** (recommended by
  `docs/research/multi-feature-navigation.md`): narrower, but other features'
  status is hidden while one is open.
- **Icon rail, about 370 pt**: status stays visible, but icons alone are harder to
  recognize.
- **Cards that expand in place**: an expanded feature pushes the others away, which
  stops working after about three features.
