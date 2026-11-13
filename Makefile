buid::
	docker build . -t wcc-fortified-test:latest

run::
	docker run -v /tmp:/tmp/ -it wcc-fortified-test:latest /home/ubuntu/mk_fortify_pocs.sh
	docker run -v /tmp:/tmp/ -it wcc-fortified-test:latest wsh -x /home/ubuntu/verify_pocs.wsh

