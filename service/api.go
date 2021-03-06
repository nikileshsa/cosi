package service

import (
	"errors"

	"github.com/dedis/cothority/log"
	"github.com/dedis/cothority/sda"
)

// Client is a structure to communicate with the CoSi
// service
type Client struct {
	*sda.Client
}

// NewClient instantiates a new cosi.Client
func NewClient() *Client {
	return &Client{Client: sda.NewClient(ServiceName)}
}

// SignMsg sends a CoSi sign request to the Cothority defined by the given
// Roster
func (c *Client) SignMsg(r *sda.Roster, msg []byte) (*SignatureResponse, error) {
	serviceReq := &SignatureRequest{
		Roster:  r,
		Message: msg,
	}
	dst := r.List[0]
	log.Lvl4("Sending message to", dst)
	reply, err := c.Send(dst, serviceReq)
	if e := sda.ErrMsg(reply, err); e != nil {
		return nil, e
	}
	sr, ok := reply.Msg.(SignatureResponse)
	if !ok {
		return nil, errors.New("This is odd: couldn't cast reply.")
	}
	return &sr, nil
}
