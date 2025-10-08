"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const verify_1 = require("../services/credentials/handlers/verify");
const router = (0, express_1.Router)();
router.post('/credentials', verify_1.verifyCredential);
exports.default = router;
//# sourceMappingURL=credentials.js.map