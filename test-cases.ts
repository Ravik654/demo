import { Test, TestingModule } from '@nestjs/testing';
import { AgentsController } from './agents.controller';
import { AgentsService } from './agents.service';
import { UtilsService } from '../utils/utils.service';
import { ForbiddenException } from '@nestjs/common';
import { UserType } from '../enums/user-type.enum';
import { Readable } from 'stream';

describe('AgentsController', () => {
  let controller: AgentsController;
  let agentsService: jest.Mocked<AgentsService>;
  let utilsService: jest.Mocked<UtilsService>;

  const mockReadable = new Readable({
    read() {
      this.push('document data');
      this.push(null);
    }
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AgentsController],
      providers: [
        {
          provide: AgentsService,
          useValue: {
            getDocument: jest.fn(),
          },
        },
        {
          provide: UtilsService,
          useValue: {
            getUserFromToken: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<AgentsController>(AgentsController);
    agentsService = module.get(AgentsService);
    utilsService = module.get(UtilsService);
  });

  describe('getDocument', () => {
    const docId = '123';
    const authHeader = 'Bearer token';
    const mockResponse = {
      pipe: jest.fn(),
    };

    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should successfully get document when user is HomeOffice type', async () => {
      // Arrange
      const userInfo = {
        loginId: 'user1',
        agentId: 'agent1',
        userType: UserType.HomeOffice
      };
      utilsService.getUserFromToken.mockReturnValue(userInfo);
      agentsService.getDocument.mockResolvedValue(mockReadable);

      // Act
      await controller.getDocument(docId, mockResponse as any);

      // Assert
      expect(utilsService.getUserFromToken).toHaveBeenCalledWith(authHeader);
      expect(agentsService.getDocument).toHaveBeenCalledWith(docId, undefined);
      expect(mockResponse.pipe).toHaveBeenCalledWith(mockReadable);
    });

    it('should successfully get document when agentId matches loginId', async () => {
      // Arrange
      const userInfo = {
        loginId: 'user1',
        agentId: 'user1', // Same as loginId
        userType: UserType.Regular
      };
      utilsService.getUserFromToken.mockReturnValue(userInfo);
      agentsService.getDocument.mockResolvedValue(mockReadable);

      // Act
      await controller.getDocument(docId, mockResponse as any);

      // Assert
      expect(utilsService.getUserFromToken).toHaveBeenCalledWith(authHeader);
      expect(agentsService.getDocument).toHaveBeenCalledWith(docId, undefined);
      expect(mockResponse.pipe).toHaveBeenCalledWith(mockReadable);
    });

    it('should throw ForbiddenException when userType is not HomeOffice and agentId does not match loginId', async () => {
      // Arrange
      const userInfo = {
        loginId: 'user1',
        agentId: 'differentAgent', // Different from loginId
        userType: UserType.Regular // Not HomeOffice
      };
      utilsService.getUserFromToken.mockReturnValue(userInfo);

      // Act & Assert
      await expect(controller.getDocument(docId, mockResponse as any))
        .rejects.toThrow(ForbiddenException);
      
      expect(utilsService.getUserFromToken).toHaveBeenCalledWith(authHeader);
      expect(agentsService.getDocument).not.toHaveBeenCalled();
      expect(mockResponse.pipe).not.toHaveBeenCalled();
    });

    it('should handle service errors gracefully', async () => {
      // Arrange
      const userInfo = {
        loginId: 'user1',
        agentId: 'user1',
        userType: UserType.Regular
      };
      utilsService.getUserFromToken.mockReturnValue(userInfo);
      const serviceError = new Error('Service error');
      agentsService.getDocument.mockRejectedValue(serviceError);

      // Act & Assert
      await expect(controller.getDocument(docId, mockResponse as any))
        .rejects.toThrow('Service error');
      
      expect(utilsService.getUserFromToken).toHaveBeenCalledWith(authHeader);
      expect(agentsService.getDocument).toHaveBeenCalledWith(docId, undefined);
    });

    it('should pass contentType parameter when provided', async () => {
      // Arrange
      const userInfo = {
        loginId: 'user1',
        agentId: 'user1',
        userType: UserType.Regular
      };
      const contentType = 'application/pdf';
      utilsService.getUserFromToken.mockReturnValue(userInfo);
      agentsService.getDocument.mockResolvedValue(mockReadable);

      // Act
      await controller.getDocument(docId, mockResponse as any, contentType);

      // Assert
      expect(agentsService.getDocument).toHaveBeenCalledWith(docId, contentType);
    });
  });
});
