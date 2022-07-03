docker-compose -f docker-compose.test.yml up -d
go test -tags=integration -v './...'  -count=1
docker-compose -f docker-compose.test.yml down
docker volume rm backend_db_volume
echo "Press any key to exit..."
read -n 1