.PHONY: build clean rel sbm_up

build: ./syscfg
./syscfg: ./src/syscfg.sh
	sh ./scripts/build.sh ./src/syscfg.sh

clean:
	rm ./syscfg

rel:
	@test -n "$(REL)" || { echo 'REL is empty'; exit 2; }
	@test -n "$(PRE)" || { echo 'PRE is empty'; exit 2; }
	@test -n "$(CUR)" || { echo 'CUR is empty'; exit 2; }
	@test -n "$(NEWS)" || { echo 'NEWS is empty'; exit 2; }
	sh ./scripts/rel.sh "$(REL)" "$(PRE)" "$(CUR)" "$(NEWS)"

sbm_up:
	@test -n "$(SUB)" || { echo 'SUB is empty'; exit 2; }
	@test -n "$(TAG)" || { echo 'TAG is empty'; exit 2; }
	sh ./scripts/sbm_up.sh "$(SUB)" "$(TAG)"
