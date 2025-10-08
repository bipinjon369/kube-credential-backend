"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const helmet_1 = __importDefault(require("helmet"));
const cors_1 = __importDefault(require("cors"));
const uuid_1 = require("uuid");
const credentials_1 = __importDefault(require("./routes/credentials"));
const app = (0, express_1.default)();
// Security middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)());
// Body parsing
app.use(express_1.default.json());
// Request ID middleware
app.use((req, res, next) => {
    req.requestId = (0, uuid_1.v4)();
    next();
});
// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'issuance' });
});
// Routes
app.use('/issuance', credentials_1.default);
// Error handling
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        message: 'Internal server error'
    });
});
exports.default = app;
//# sourceMappingURL=app.js.map