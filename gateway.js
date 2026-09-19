const express = require('express');
const soap = require('soap');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const fs = require('fs');

const packageDefinition = protoLoader.loadSync('organ_transport.proto');
const proto = grpc.loadPackageDefinition(packageDefinition).organ_transport;

const GRPC_HOST = process.env.GRPC_HOST || 'localhost:50051';
const grpcClient = new proto.OrganTransportService(GRPC_HOST, grpc.credentials.createInsecure());

const soapService = {
  OrganTransportSOAPService: {
    OrganTransportPort: {
      ReserveOrgan: function(args, callback) {
        const grpcPayload = {
          donor_id: args.donorId,
          organ_type: args.organType,
          hospital_id: parseInt(args.hospitalId, 10)
        };

        grpcClient.ReserveOrgan(grpcPayload, (err, response) => {
          if (err) {
            let faultCode = "Receiver";
            if (err.code === grpc.status.INVALID_ARGUMENT || err.code === grpc.status.NOT_FOUND) {
              faultCode = "Sender";
            }

            return callback({
              Fault: {
                faultcode: faultCode,
                faultstring: err.details,
                detail: { grpcCode: err.code }
              }
            });
          }

          callback(null, {
            reservationId: response.reservation_id,
            status: response.status,
            viabilityMinutes: response.viability_minutes
          });
        });
      }
    }
  }
};

const xml = fs.readFileSync('organ_transport.wsdl', 'utf8');
const app = express();
app.use(express.raw({ type: () => true, limit: '5mb' }));

app.listen(8000, function() {
  soap.listen(app, '/soap', soapService, xml);
  console.log("Translating SOAP Gateway listening on port 8000");
});