"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const issue_1 = require("../services/credentials/handlers/issue");
const router = (0, express_1.Router)();
router.post('/credentials', issue_1.issueCredential);
exports.default = router;
//# sourceMappingURL=credentials.js.map