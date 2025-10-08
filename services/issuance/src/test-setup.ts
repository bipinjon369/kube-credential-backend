// Mock database connection for tests
jest.mock('./lib/aws/rds_knex', () => ({
  createDatabaseConnection: () => ({
    select: jest.fn(),
    where: jest.fn().mockReturnThis(),
    first: jest.fn(),
    insert: jest.fn(),
  })
}));