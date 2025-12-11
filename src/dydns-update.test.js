const nock = require("nock");
const { updateRecord } = require("./dydns-update");

// Mock environment variables
process.env.INWX_USER = "testuser";
process.env.INWX_PASS = "testpass";
process.env.DOMAIN = "test.com";
process.env.RECORD_NAME = "myhome";

const API_URL = "https://api.domrobot.com";
const IPIFY_URL = "https://api.ipify.org";

describe("updateRecord", () => {
    beforeEach(() => {
        nock.cleanAll();
        // Mock console to prevent logs from appearing in test output
        jest.spyOn(console, "log").mockImplementation(() => {});
        jest.spyOn(console, "error").mockImplementation(() => {});
        jest.spyOn(process, 'exit').mockImplementation(() => {
            throw new Error('process.exit() was called');
        });
    });

    afterEach(() => {
        nock.restore();
        jest.restoreAllMocks();
    });

    test("should update an existing record if the IP has changed", async () => {
        const newIp = "123.123.123.123";
        const oldIp = "100.100.100.100";

        // 1. Mock getPublicIP
        nock(IPIFY_URL).get("/?format=json").reply(200, { ip: newIp });

        // 2. Mock inwxCall for domain.info
        nock(API_URL)
            .post("/v3/domrobot", (body) => body.method === "domain.info")
            .reply(200, { result: { id: 12345 } });

        // 3. Mock inwxCall for nameserver.info
        nock(API_URL)
            .post("/v3/domrobot", (body) => body.method === "nameserver.info")
            .reply(200, {
                result: {
                    record: [
                        { id: 54321, name: process.env.RECORD_NAME, type: "A", content: oldIp },
                        { id: 54322, name: "other", type: "A", content: "1.2.3.4" }
                    ]
                }
            });
            
        // 4. Mock inwxCall for nameserver.updateRecord
        const updateMock = nock(API_URL)
            .post("/v3/domrobot", (body) => {
                return body.method === "nameserver.updateRecord" && body.params.id === 54321 && body.params.content === newIp;
            })
            .reply(200, { result: {} });

        await updateRecord();

        expect(updateMock.isDone()).toBe(true);
        expect(console.log).toHaveBeenCalledWith(`[OK] Record aktualisiert: ${process.env.RECORD_NAME}.${process.env.DOMAIN} → ${newIp}`);
    });
});
