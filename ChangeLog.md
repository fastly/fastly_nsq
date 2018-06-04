# Change Log

## [v1.9.0](https://github.com/fastly/fastly_nsq/tree/v1.9.0) (2018-06-04)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.8.0...v1.9.0)

**Merged pull requests:**

- Support writing multiple messages in FastlyNsq::Messenger [\#81](https://github.com/fastly/fastly_nsq/pull/81) ([leklund](https://github.com/leklund))
- Remove README line about point release... [\#80](https://github.com/fastly/fastly_nsq/pull/80) ([alieander](https://github.com/alieander))
- Document lifecycle methods [\#79](https://github.com/fastly/fastly_nsq/pull/79) ([lanej](https://github.com/lanej))
- update default ruby version to latest stable [\#78](https://github.com/fastly/fastly_nsq/pull/78) ([lanej](https://github.com/lanej))

## [v1.8.0](https://github.com/fastly/fastly_nsq/tree/v1.8.0) (2018-05-30)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.7.0...v1.8.0)

**Merged pull requests:**

- add lifecyle callbacks [\#77](https://github.com/fastly/fastly_nsq/pull/77) ([lanej](https://github.com/lanej))
- Add YARD-style documentation. [\#76](https://github.com/fastly/fastly_nsq/pull/76) ([leklund](https://github.com/leklund))

## [v1.7.0](https://github.com/fastly/fastly_nsq/tree/v1.7.0) (2018-04-26)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.6.0...v1.7.0)

**Merged pull requests:**

- Add `sent\_at` to `meta` when `deliver` is called. [\#75](https://github.com/fastly/fastly_nsq/pull/75) ([set5think](https://github.com/set5think))

## [v1.6.0](https://github.com/fastly/fastly_nsq/tree/v1.6.0) (2018-04-17)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.5.0...v1.6.0)

**Merged pull requests:**

- add FastlyNsq::Testing.message [\#74](https://github.com/fastly/fastly_nsq/pull/74) ([lanej](https://github.com/lanej))

## [v1.5.0](https://github.com/fastly/fastly_nsq/tree/v1.5.0) (2018-04-16)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.4.1...v1.5.0)

**Merged pull requests:**

- standardize logging format and add attempts [\#71](https://github.com/fastly/fastly_nsq/pull/71) ([lanej](https://github.com/lanej))

## [v1.4.1](https://github.com/fastly/fastly_nsq/tree/v1.4.1) (2018-04-12)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.4.0...v1.4.1)

**Merged pull requests:**

- Cap the requeue\_period calculation at 30 attempts. [\#73](https://github.com/fastly/fastly_nsq/pull/73) ([leklund](https://github.com/leklund))

## [v1.4.0](https://github.com/fastly/fastly_nsq/tree/v1.4.0) (2018-04-12)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.3.0...v1.4.0)

**Merged pull requests:**

- add exponential retries to FastlyNsq::Message [\#72](https://github.com/fastly/fastly_nsq/pull/72) ([leklund](https://github.com/leklund))

## [v1.3.0](https://github.com/fastly/fastly_nsq/tree/v1.3.0) (2018-04-11)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.2.0...v1.3.0)

**Merged pull requests:**

- global max\_attempts setting [\#70](https://github.com/fastly/fastly_nsq/pull/70) ([lanej](https://github.com/lanej))

## [v1.2.0](https://github.com/fastly/fastly_nsq/tree/v1.2.0) (2018-04-11)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.1.0...v1.2.0)

**Merged pull requests:**

- feature: allow specifications of consumer options via listener [\#69](https://github.com/fastly/fastly_nsq/pull/69) ([lanej](https://github.com/lanej))

## [v1.1.0](https://github.com/fastly/fastly_nsq/tree/v1.1.0) (2018-02-20)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.0.2...v1.1.0)

**Merged pull requests:**

- upgrade nsq-ruby to ~\> 2.2 [\#68](https://github.com/fastly/fastly_nsq/pull/68) ([leklund](https://github.com/leklund))

## [v1.0.2](https://github.com/fastly/fastly_nsq/tree/v1.0.2) (2018-01-05)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.0.1...v1.0.2)

**Merged pull requests:**

- fix: launcher heartbeat [\#67](https://github.com/fastly/fastly_nsq/pull/67) ([lanej](https://github.com/lanej))

## [v1.0.1](https://github.com/fastly/fastly_nsq/tree/v1.0.1) (2018-01-05)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v1.0.0...v1.0.1)

**Merged pull requests:**

- fix: launcher correctly uses manager [\#66](https://github.com/fastly/fastly_nsq/pull/66) ([lanej](https://github.com/lanej))

## [v1.0.0](https://github.com/fastly/fastly_nsq/tree/v1.0.0) (2018-01-05)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.13.2...v1.0.0)

**Closed issues:**

- We should use NSQ\_LOOKUPD to produce as well [\#28](https://github.com/fastly/fastly_nsq/issues/28)

**Merged pull requests:**

- Consumer read loops send work to a central, prioritized thread pool [\#65](https://github.com/fastly/fastly_nsq/pull/65) ([lanej](https://github.com/lanej))

## [v0.13.2](https://github.com/fastly/fastly_nsq/tree/v0.13.2) (2017-12-04)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.13.0...v0.13.2)

**Merged pull requests:**

- Retrieve meta section of message [\#64](https://github.com/fastly/fastly_nsq/pull/64) ([set5think](https://github.com/set5think))
- Don't log the logger object when creating a listener. [\#63](https://github.com/fastly/fastly_nsq/pull/63) ([leklund](https://github.com/leklund))
- Set metadata [\#62](https://github.com/fastly/fastly_nsq/pull/62) ([set5think](https://github.com/set5think))
- To rubocop update [\#61](https://github.com/fastly/fastly_nsq/pull/61) ([alieander](https://github.com/alieander))

## [v0.13.0](https://github.com/fastly/fastly_nsq/tree/v0.13.0) (2017-11-29)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.12.4...v0.13.0)

**Merged pull requests:**

- fix: store topic on produced mock message [\#60](https://github.com/fastly/fastly_nsq/pull/60) ([lanej](https://github.com/lanej))
- Implement Most Nsqd and Nsqlookupd Http api's [\#59](https://github.com/fastly/fastly_nsq/pull/59) ([alieander](https://github.com/alieander))

## [v0.12.4](https://github.com/fastly/fastly_nsq/tree/v0.12.4) (2017-11-02)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.12.2...v0.12.4)

**Merged pull requests:**

- remove connection timeout on initialization [\#58](https://github.com/fastly/fastly_nsq/pull/58) ([alieander](https://github.com/alieander))
- Only raise if consumer is empty [\#57](https://github.com/fastly/fastly_nsq/pull/57) ([alieander](https://github.com/alieander))

## [v0.12.2](https://github.com/fastly/fastly_nsq/tree/v0.12.2) (2017-09-12)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.12.1...v0.12.2)

**Merged pull requests:**

- terminate should also end the threads life... [\#56](https://github.com/fastly/fastly_nsq/pull/56) ([alieander](https://github.com/alieander))

## [v0.12.1](https://github.com/fastly/fastly_nsq/tree/v0.12.1) (2017-09-06)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.12.0...v0.12.1)

**Merged pull requests:**

- Cleanup in the terminate and kill methods [\#55](https://github.com/fastly/fastly_nsq/pull/55) ([alieander](https://github.com/alieander))

## [v0.12.0](https://github.com/fastly/fastly_nsq/tree/v0.12.0) (2017-08-18)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.10.1...v0.12.0)

**Merged pull requests:**

- This should load rails correctly. [\#54](https://github.com/fastly/fastly_nsq/pull/54) ([alieander](https://github.com/alieander))
- Add accessor for Nsq::Message object and delegate methods [\#53](https://github.com/fastly/fastly_nsq/pull/53) ([leklund](https://github.com/leklund))
- Cleanup / Warning removal [\#51](https://github.com/fastly/fastly_nsq/pull/51) ([alieander](https://github.com/alieander))

## [v0.10.1](https://github.com/fastly/fastly_nsq/tree/v0.10.1) (2017-07-14)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.10.0...v0.10.1)

**Merged pull requests:**

- Add topic to listener log lines. [\#52](https://github.com/fastly/fastly_nsq/pull/52) ([leklund](https://github.com/leklund))

## [v0.10.0](https://github.com/fastly/fastly_nsq/tree/v0.10.0) (2017-06-09)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.9.5...v0.10.0)

**Merged pull requests:**

- Setup a possible path to daemonize listeners [\#49](https://github.com/fastly/fastly_nsq/pull/49) ([alieander](https://github.com/alieander))

## [v0.9.5](https://github.com/fastly/fastly_nsq/tree/v0.9.5) (2017-05-25)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.9.4...v0.9.5)

**Merged pull requests:**

- Consumer should connect on initialize [\#50](https://github.com/fastly/fastly_nsq/pull/50) ([leklund](https://github.com/leklund))

## [v0.9.4](https://github.com/fastly/fastly_nsq/tree/v0.9.4) (2017-04-13)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.9.3...v0.9.4)

**Merged pull requests:**

- catch, log, and terminate to ensure producer dies [\#48](https://github.com/fastly/fastly_nsq/pull/48) ([alieander](https://github.com/alieander))

## [v0.9.3](https://github.com/fastly/fastly_nsq/tree/v0.9.3) (2017-01-19)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.9.2...v0.9.3)

**Merged pull requests:**

- Wait for Producer to connect. [\#47](https://github.com/fastly/fastly_nsq/pull/47) ([alieander](https://github.com/alieander))

## [v0.9.2](https://github.com/fastly/fastly_nsq/tree/v0.9.2) (2017-01-17)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.9.1...v0.9.2)

**Merged pull requests:**

- bump version to 0.9.2 [\#46](https://github.com/fastly/fastly_nsq/pull/46) ([alieander](https://github.com/alieander))
- we should produce to a lookup as well [\#45](https://github.com/fastly/fastly_nsq/pull/45) ([alieander](https://github.com/alieander))

## [v0.9.1](https://github.com/fastly/fastly_nsq/tree/v0.9.1) (2017-01-04)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.9.0...v0.9.1)

**Merged pull requests:**

- update nsq-ruby dependency [\#44](https://github.com/fastly/fastly_nsq/pull/44) ([leklund](https://github.com/leklund))

## [v0.9.0](https://github.com/fastly/fastly_nsq/tree/v0.9.0) (2016-12-20)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.8.0...v0.9.0)

**Merged pull requests:**

- Reuse connections [\#43](https://github.com/fastly/fastly_nsq/pull/43) ([leklund](https://github.com/leklund))

## [v0.8.0](https://github.com/fastly/fastly_nsq/tree/v0.8.0) (2016-11-29)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.7.1...v0.8.0)

**Merged pull requests:**

- Upgrade to nsq-ruby version 2.0.3 [\#42](https://github.com/fastly/fastly_nsq/pull/42) ([alieander](https://github.com/alieander))

## [v0.7.1](https://github.com/fastly/fastly_nsq/tree/v0.7.1) (2016-10-26)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.7.0...v0.7.1)

**Merged pull requests:**

- Allow the use of multiple lookups [\#40](https://github.com/fastly/fastly_nsq/pull/40) ([alieander](https://github.com/alieander))

## [v0.7.0](https://github.com/fastly/fastly_nsq/tree/v0.7.0) (2016-08-10)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.6.0...v0.7.0)

**Closed issues:**

- \[RFC\] Use JSON schemata to validate messages before publishing [\#31](https://github.com/fastly/fastly_nsq/issues/31)

**Merged pull requests:**

- Colons help the world go ... [\#39](https://github.com/fastly/fastly_nsq/pull/39) ([alieander](https://github.com/alieander))
- call Thread\#join only on threads we created [\#38](https://github.com/fastly/fastly_nsq/pull/38) ([alieander](https://github.com/alieander))
- Consistent use of namespace & injectable dependencies [\#37](https://github.com/fastly/fastly_nsq/pull/37) ([jaw6](https://github.com/jaw6))
- Remove broadcast Address [\#36](https://github.com/fastly/fastly_nsq/pull/36) ([alieander](https://github.com/alieander))
- Update PR template to warn against Jira URLs [\#35](https://github.com/fastly/fastly_nsq/pull/35) ([adarsh](https://github.com/adarsh))
- Update TravisCI \> Slack integration key [\#34](https://github.com/fastly/fastly_nsq/pull/34) ([adarsh](https://github.com/adarsh))

## [v0.6.0](https://github.com/fastly/fastly_nsq/tree/v0.6.0) (2016-05-13)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.5.1...v0.6.0)

**Merged pull requests:**

- Producer\#connection -\> Producer [\#29](https://github.com/fastly/fastly_nsq/pull/29) ([jaw6](https://github.com/jaw6))

## [v0.5.1](https://github.com/fastly/fastly_nsq/tree/v0.5.1) (2016-05-12)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.5.0...v0.5.1)

**Closed issues:**

- Listener spec seems todo nothing. [\#27](https://github.com/fastly/fastly_nsq/issues/27)

**Merged pull requests:**

- Persist connection [\#32](https://github.com/fastly/fastly_nsq/pull/32) ([jaw6](https://github.com/jaw6))
- Remove unnecessary listener spec [\#30](https://github.com/fastly/fastly_nsq/pull/30) ([adarsh](https://github.com/adarsh))

## [v0.5.0](https://github.com/fastly/fastly_nsq/tree/v0.5.0) (2016-05-10)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.4.0...v0.5.0)

**Merged pull requests:**

- Should Listener\#consumer -\> Consumer, or Consumer\#connection? [\#26](https://github.com/fastly/fastly_nsq/pull/26) ([jaw6](https://github.com/jaw6))

## [v0.4.0](https://github.com/fastly/fastly_nsq/tree/v0.4.0) (2016-04-21)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.3.1...v0.4.0)

**Merged pull requests:**

- Add SSLContext to fastly\_nsq [\#25](https://github.com/fastly/fastly_nsq/pull/25) ([alieander](https://github.com/alieander))

## [v0.3.1](https://github.com/fastly/fastly_nsq/tree/v0.3.1) (2016-03-29)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.3.0...v0.3.1)

**Merged pull requests:**

- Update rake to 11.1.2 [\#24](https://github.com/fastly/fastly_nsq/pull/24) ([adarsh](https://github.com/adarsh))
- Add Rubocop and Overcommit [\#23](https://github.com/fastly/fastly_nsq/pull/23) ([adarsh](https://github.com/adarsh))

## [v0.3.0](https://github.com/fastly/fastly_nsq/tree/v0.3.0) (2016-03-17)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.2.3...v0.3.0)

**Merged pull requests:**

- Listen to multiple queues at once [\#22](https://github.com/fastly/fastly_nsq/pull/22) ([adarsh](https://github.com/adarsh))

## [v0.2.3](https://github.com/fastly/fastly_nsq/tree/v0.2.3) (2016-03-11)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.2.2...v0.2.3)

**Merged pull requests:**

- Add a PULL\_REQUEST\_TEMPLATE.md [\#20](https://github.com/fastly/fastly_nsq/pull/20) ([alieander](https://github.com/alieander))
- Cleanup rake\_task tests; Extend examples [\#19](https://github.com/fastly/fastly_nsq/pull/19) ([alieander](https://github.com/alieander))
- Allow a logger to be defined on underlying nsq gem [\#16](https://github.com/fastly/fastly_nsq/pull/16) ([alieander](https://github.com/alieander))

## [v0.2.2](https://github.com/fastly/fastly_nsq/tree/v0.2.2) (2016-03-10)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.2.1...v0.2.2)

**Fixed bugs:**

- Have the fake consumer block on an empty queue [\#13](https://github.com/fastly/fastly_nsq/pull/13) ([adarsh](https://github.com/adarsh))

**Merged pull requests:**

- Add RSpec fake\_queue: true|false flags [\#17](https://github.com/fastly/fastly_nsq/pull/17) ([adarsh](https://github.com/adarsh))
- Bump to 0.2.2 [\#14](https://github.com/fastly/fastly_nsq/pull/14) ([adarsh](https://github.com/adarsh))
- Raise custom exeception for empty fake queue [\#12](https://github.com/fastly/fastly_nsq/pull/12) ([adarsh](https://github.com/adarsh))

## [v0.2.1](https://github.com/fastly/fastly_nsq/tree/v0.2.1) (2016-02-26)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.2.0...v0.2.1)

**Merged pull requests:**

- Bump version to 0.2.1 [\#11](https://github.com/fastly/fastly_nsq/pull/11) ([adarsh](https://github.com/adarsh))
- Implement termination of the fake connections [\#10](https://github.com/fastly/fastly_nsq/pull/10) ([adarsh](https://github.com/adarsh))

## [v0.2.0](https://github.com/fastly/fastly_nsq/tree/v0.2.0) (2016-02-26)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.1.4...v0.2.0)

**Merged pull requests:**

- Use RSpec [\#9](https://github.com/fastly/fastly_nsq/pull/9) ([adarsh](https://github.com/adarsh))
- Terminate producer and consumer connections [\#8](https://github.com/fastly/fastly_nsq/pull/8) ([adarsh](https://github.com/adarsh))
- Fix test errors [\#7](https://github.com/fastly/fastly_nsq/pull/7) ([adarsh](https://github.com/adarsh))
- To add listener rake task [\#6](https://github.com/fastly/fastly_nsq/pull/6) ([alieander](https://github.com/alieander))

## [v0.1.4](https://github.com/fastly/fastly_nsq/tree/v0.1.4) (2016-02-11)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.1.3...v0.1.4)

**Merged pull requests:**

- Bump version to 0.1.4 [\#5](https://github.com/fastly/fastly_nsq/pull/5) ([adarsh](https://github.com/adarsh))
- Initialize the fake queue with an empty array [\#4](https://github.com/fastly/fastly_nsq/pull/4) ([adarsh](https://github.com/adarsh))

## [v0.1.3](https://github.com/fastly/fastly_nsq/tree/v0.1.3) (2016-02-03)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.1.1...v0.1.3)

**Merged pull requests:**

- Use a more canonical way to require files [\#3](https://github.com/fastly/fastly_nsq/pull/3) ([adarsh](https://github.com/adarsh))
- Remove dependancy on ActiveSupport [\#2](https://github.com/fastly/fastly_nsq/pull/2) ([adarsh](https://github.com/adarsh))

## [v0.1.1](https://github.com/fastly/fastly_nsq/tree/v0.1.1) (2016-02-03)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.0.2...v0.1.1)

## [v0.0.2](https://github.com/fastly/fastly_nsq/tree/v0.0.2) (2016-02-03)
[Full Changelog](https://github.com/fastly/fastly_nsq/compare/v0.0.1...v0.0.2)

**Merged pull requests:**

- Refactor to move up Producer/Consumer classes [\#1](https://github.com/fastly/fastly_nsq/pull/1) ([adarsh](https://github.com/adarsh))

## [v0.0.1](https://github.com/fastly/fastly_nsq/tree/v0.0.1) (2016-01-30)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*