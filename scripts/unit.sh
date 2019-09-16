cp .env.test .env
docker-compose -f docker-compose.test.yml run --rm units
rm .env
