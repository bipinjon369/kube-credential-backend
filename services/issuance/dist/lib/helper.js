"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createEndpointLogger = exports.generateUUID = exports.getWorkerID = void 0;
const os_1 = __importDefault(require("os"));
const uuid_1 = require("uuid");
const winston_1 = __importDefault(require("winston"));
const getWorkerID = () => {
    return process.env.WORKER_ID || os_1.default.hostname();
};
exports.getWorkerID = getWorkerID;
const generateUUID = () => {
    return (0, uuid_1.v4)();
};
exports.generateUUID = generateUUID;
const createEndpointLogger = (endpoint, method) => {
    return winston_1.default.createLogger({
        level: process.env.LOG_LEVEL || 'info',
        format: winston_1.default.format.combine(winston_1.default.format.timestamp(), winston_1.default.format.errors({ stack: true }), winston_1.default.format.json()),
        defaultMeta: { endpoint, method },
        transports: [
            new winston_1.default.transports.Console({
                format: winston_1.default.format.combine(winston_1.default.format.colorize(), winston_1.default.format.simple())
            })
        ]
    });
};
exports.createEndpointLogger = createEndpointLogger;
//# sourceMappingURL=helper.js.map