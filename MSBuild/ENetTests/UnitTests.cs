/*
 * Copyright (c) 2019 Chris Burns <chris@kitty.city>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
using NUnit.Framework;
using System;
using System.Net;
using System.Diagnostics;
using ENet;
using System.Linq;

public class UnitTests
{
    enum ClientState
    {
        None,
        Connecting,
        Connected,
        SendData,
        RecvData,
        Disconnecting,
        Disconnected,
    }

    [OneTimeSetUp]
    public void FixtureSetup()
    {
    }

    [OneTimeTearDown]
    public void FixtureCleanup()
    {
    }

    [SetUp]
    public void TestSetup()
    {
    }

    [TearDown]
    public void TestCleanup()
    {
    }

    [Test]
    public void InitAndUninit()
    {
        using (Host host = new Host())
        {
        }
    }

    [Test]
    [TestCase(false, 1)]
    [TestCase(false, 2)]
    [TestCase(false, 3)]
    [TestCase(false, 4)]
    [TestCase(false, 5)]
    [TestCase(true, 1)]
    [TestCase(true, 2)]
    [TestCase(true, 3)]
    [TestCase(true, 4)]
    [TestCase(true, 5)]
    public void SendAndRecv(bool useSsl, int maxClients)
    {
        const ushort port = 7777;
        const byte dataVal = 42;

        int[] clientEvents = new int[maxClients];
        int clientConnected = 0;
        int clientDisconnected = 0;
        int clientTimeout = 0;
        int clientNone = 0;
        int clientRecvData = 0;
        int serverEvents = 0;
        int serverConnected = 0;
        int serverDisconnected = 0;
        int serverRecvData = 0;
        int serverTimeout = 0;
        int serverNone = 0;

        ClientState[] clientStates = new ClientState[maxClients];

        Host[] clients = new Host[maxClients];
        for (int i = 0; i < clients.Length; i++)
        {
            clients[i] = new Host();
        }
        Host server = new Host();
        try
        {
            Address address = new Address();
            address.Port = port;

            SslConfiguration serverConfiguration = new SslConfiguration();
            SslConfiguration clientConfiguration = new SslConfiguration();

            if (useSsl)
            {
                serverConfiguration.Mode = SslMode.Server;
                serverConfiguration.CertificatePath = "testCert.pem";
                serverConfiguration.PrivateKeyPath = "testKey.pem";

                clientConfiguration.Mode = SslMode.Client;
                clientConfiguration.ValidateCertificate = false;
            }

            server.Create(address, maxClients, sslConfiguration: serverConfiguration);
            address.SetIP("127.0.0.1");

            foreach (var client in clients)
            {
                client.Create(sslConfiguration: clientConfiguration);
            }

            Peer[] clientPeers = new Peer[clients.Length];
            Stopwatch sw = Stopwatch.StartNew();
            while (clientStates.Any(clientState => clientState != ClientState.Disconnected) && sw.ElapsedMilliseconds < 10000)
            {
                while (server.Service(15, out Event netEvent) > 0)
                {
                    serverEvents++;
                    switch (netEvent.Type)
                    {
                        case EventType.None:
                            serverNone++;
                            break;
                        case EventType.Connect:
                            serverConnected++;
                            break;
                        case EventType.Disconnect:
                            serverDisconnected++;
                            for (int c2 = 0; c2 < clientStates.Length; c2++)
                            {
                                // disconnect the first disconnecting client (doesn't really matter which one)
                                if (clientStates[c2] == ClientState.Disconnecting)
                                {
                                    clientStates[c2] = ClientState.Disconnected;
                                    break;
                                }
                            }
                            break;
                        case EventType.Timeout:
                            serverTimeout++;
                            break;
                        case EventType.Receive:
                            serverRecvData++;
                            Packet packet = default(Packet);
                            byte[] data = new byte[64];
                            netEvent.Packet.CopyTo(data);

                            for (int i = 0; i < data.Length; i++) Assert.True(data[i] == dataVal);

                            packet.Create(data);
                            netEvent.Peer.Send(0, ref packet);
                            netEvent.Packet.Dispose();
                            break;
                    }
                }
                server.Flush();

                for (int c = 0; c < clients.Length; c++)
                {
                    var client = clients[c];
                    while (client.Service(15, out Event netEvent) > 0)
                    {
                        clientEvents[c]++;
                        switch (netEvent.Type)
                        {
                            case EventType.None:
                                clientNone++;
                                break;
                            case EventType.Connect:
                                clientConnected++;
                                clientStates[c] = ClientState.Connected;
                                break;
                            case EventType.Disconnect:
                                clientDisconnected++;
                                clientStates[c] = ClientState.Disconnected;
                                break;
                            case EventType.Timeout:
                                clientTimeout++;
                                break;
                            case EventType.Receive:
                                clientRecvData++;
                                byte[] data = new byte[64];
                                Packet packet = netEvent.Packet;
                                packet.CopyTo(data);
                                for (int i = 0; i < data.Length; i++) Assert.True(data[i] == dataVal);
                                netEvent.Packet.Dispose();

                                clientStates[c] = ClientState.RecvData;
                                break;
                        }
                    }
                    client.Flush();

                    if (clientStates[c] == ClientState.None)
                    {
                        clientStates[c] = ClientState.Connecting;
                        clientPeers[c] = client.Connect(address);
                    }
                    else if (clientStates[c] == ClientState.Connected)
                    {
                        Packet packet = default(Packet);
                        byte[] data = new byte[64];
                        for (int i = 0; i < data.Length; i++) data[i] = dataVal;

                        packet.Create(data);
                        clientPeers[c].Send(0, ref packet);

                        clientStates[c] = ClientState.SendData;
                    }
                    else if (clientStates[c] == ClientState.RecvData)
                    {
                        clientPeers[c].DisconnectNow(0);
                        clientStates[c] = ClientState.Disconnecting;
                    }
                }
            }
        }
        finally
        {
            server.Dispose();
            foreach (var client in clients)
            {
                client.Dispose();
            }
        }

        for (int c = 0; c < clientEvents.Length; c++)
        {
            Assert.True(clientEvents[c] != 0, "client host never generated an event");
        }
        Assert.True(serverEvents != 0, "server host never generated an event");

        for (int c = 0; c < clients.Length; c++)
        {
            Assert.True(clientStates[c] == ClientState.Disconnected, "client didn't fully disconnect");
        }

        Assert.AreEqual(maxClients, clientConnected, "client should have connected once per client");
        Assert.AreEqual(maxClients, serverConnected, "server should have had one inbound connect per client");

        Assert.AreEqual(maxClients, clientRecvData, "client should have recvd once per client");
        Assert.AreEqual(maxClients, serverRecvData, "server should have recvd once per client");

        Assert.AreEqual(0, clientTimeout, "client had timeout events");
        Assert.AreEqual(0, serverTimeout, "server had timeout events");

        Assert.AreEqual(0, clientNone, "client had none events");
        Assert.AreEqual(0, serverNone, "server had none events");

        Assert.AreEqual(maxClients, serverDisconnected, "server should have had one client disconnect per client");
    }
}
