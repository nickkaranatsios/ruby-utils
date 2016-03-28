To compile the quic_client and quic_server programs ninja -C out/Debug quic_client quic_server
Run the quic_server first:
./out/Debug/quic_server -v=1 --certificate_file=net/tools/quic/certs/out/leaf_cert.pem --key_file=net/tools/quic/certs/out/leaf_cert.pkcs8 &> out/Debug/server.log

To run the quic_client:
./out/Debug/quic_client --disable-certificate-verification --host=127.0.0.1 --port=6121 --v=1 http://www.google.com
